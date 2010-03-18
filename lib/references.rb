module References
  def self.included(base)
    base.send :extend, ClassMethods
    
    class << base
      alias_method_chain :belongs_to, :referenced_by
      alias_method_chain :has_and_belongs_to_many, :referenced_by
      alias_method_chain :has_many, :referenced_by
    end
  end
  
  module ClassMethods
    def referenced_by(*accessors)
      @referenced_by = accessors
    end

    def has_and_belongs_to_many_with_referenced_by(model, *args)
      has_and_belongs_to_many_without_referenced_by(model, *args)
      _has_many_references(model.to_s.singularize)
    end

    def has_many_with_referenced_by(model, *args)
      has_many_without_referenced_by(model, *args)
      _has_many_references(model.to_s.singularize)
    end

    def _has_many_references(model)
      return unless association = self.reflect_on_association(model.pluralize.to_sym)
      association_class = association.class_name.constantize

      accessors = association_class.instance_variable_get('@referenced_by') || []

      accessors.each do |accessor|
        define_method "#{ model }_#{ accessor.to_s.pluralize }" do
          if s = self.send(model.pluralize)
            s.map(&accessor)
          end
        end

        define_method "#{ model }_#{ accessor.to_s.pluralize }=" do |vals|
          if vals.is_a?(String)
            vals = vals.split(/\s*,\s*/)
          end

          instances = association_class.send("find_all_by_#{ accessor }", vals)
          self.send("#{ model.pluralize }=", instances)
        end
      end
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
        
        define_method "#{ model }_#{ accessor }=" do |val|
          instance = association_class.send("find_by_#{ accessor }", val)
          self.send("#{ model }=", instance)
        end
      end
    end
  end
end

