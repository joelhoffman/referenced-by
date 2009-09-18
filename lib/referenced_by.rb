module ReferencedBy
  def self.included(base)
    base.send :extend, ClassMethods
    
    class << base
      alias_method_chain :belongs_to, :referenced_by
    end
  end
  
  module ClassMethods
    def referenced_by(*accessors_and_options)
      options = accessors_and_options.extract_options!
      @referenced_by = accessors_and_options
      @referenced_by_scope = options[:scope]
    end
    
    def belongs_to_with_referenced_by(model, *args)
      belongs_to_without_referenced_by(model, *args)
      return if self.reflections[model.to_sym].options[:polymorphic]
      association_class = self.reflections[model.to_sym].class_name.constantize  
      accessors = association_class.instance_variable_get('@referenced_by') || []
      
      accessors.each do |accessor|
        define_method "#{ model }_#{ accessor }" do
          if s = self.send(model) 
            s.send(accessor)
          end
        end
        
        if @referenced_by_scope
          r = @referenced_by_scope
          define_method "#{ model }_#{ accessor }=" do |val|
            method = "find_by_#{ accessor }_and_#{ r }"
            params = [val, self.send(r) ]
            instance = association_class.send(method, *params)
            self.send("#{ model }=", instance)
          end
        else
          define_method "#{ model }_#{ accessor }=" do |val|
            method = "find_by_#{ accessor }"
            params = [ val ]
            instance = association_class.send(method, *params)
            self.send("#{ model }=", instance)
          end
        end
      end
    end
  end
end

