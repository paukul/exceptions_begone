# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
ExceptionsBegone::Application.initialize!

Haml::Template.options[:ugly] = true
Haml::Template.options[:attr_wrapper] = '"'
