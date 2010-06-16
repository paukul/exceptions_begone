# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

AUTHLOGIC_ADDON = "db"

Rails::Initializer.run do |config|
  config.frameworks -= [ :active_record ] #, :active_resource, :action_mailer ]
  config.time_zone = 'Berlin'
  config.action_mailer.delivery_method = :sendmail
end

require "paginator"
