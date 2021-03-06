require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Sorter
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0
    # config.api_only = true
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.autoload_paths += %W(#{config.root}/app/models/application_redis)

    # FIXME: ガバガバcors
    config.action_dispatch.default_headers = {
      'Access-Control-Allow-Credentials' => 'true',
      'Access-Control-Allow-Origin' => '*', # アクセス元のURL
      'Access-Control-Request-Method' => '*' # 許可するメソッド（GET,POST,DELETEなど）：'*'は全てのメソッドという意味
    }
  end
end
