require File.dirname(__FILE__) + '/lib/referenced_by'
ActiveRecord::Base.class_eval do
  include ReferencedBy
end
