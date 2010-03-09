require File.dirname(__FILE__) + '/lib/references'
ActiveRecord::Base.class_eval do
  include References
end
