# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.2.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  
  config.load_paths += [RAILS_ROOT + '/vendor/xml-mapping/lib']
  
  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
  config.time_zone = 'UTC'

  config.action_controller.session = {
    :session_key => '_Importer_session',
    :secret      => 'f026ee2d31e58a449e74867a333d9857be3feac69342919b3a25f18b4e201ad82dd2394a737295b4d20a509a42a67994f1ac26e0967297f55b77aba9a42fedb4'
  }

  ## Ebay APP_CONFIG is loaded from config/initializers/load_config.rb
  config.after_initialize do
    ## Put ebay api configuration here. ##
    Ebay::Api.configure do |ebay|
      ebay.use_sandbox = APP_CONFIG['use_sandbox']
      ebay.auth_token = APP_CONFIG['auth_token']
      ebay.dev_id = APP_CONFIG['dev_id']
      ebay.app_id = APP_CONFIG['app_id']
      ebay.cert = APP_CONFIG['cert']
    
      ebay.username = APP_CONFIG['username']
      ebay.password = APP_CONFIG['password']
    end
  end
end
