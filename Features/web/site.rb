#
# Suraj Vijayakumar
# 11 Feb 2013
#

require 'haml'
require 'sinatra/base'
require 'sinatra/content_for'
require 'sinatra/flash'
require 'sinatra/partial'
require 'sinatra/json'

require_relative 'helpers/cache_helper'
require_relative 'helpers/database_helpers'
require_relative 'helpers/date_time_helpers'
require_relative 'helpers/diff_helpers'
require_relative 'helpers/run_result_helpers'
require_relative 'helpers/run_result_html_helpers'
require_relative 'helpers/site_helpers'
require_relative 'helpers/test_result_helpers'

module Automation

  class WebError < RuntimeError
  end

  # The WebApp application.
  class WebApp < Sinatra::Application

    include Automation::Kernel

    # Static content types
    STATIC_MIME_TYPES = {'.xml' => 'text/xml',
                         '.log' => 'text/plain', '.txt' => 'text/plain'}

    # The automation environment.
    env = Automation.environment
    config_manager = env.config_manager

    # Add support for the partial and render methods in HAML.
    register Sinatra::Partial
    # Add support for the content_for and yield_content methods.
    helpers Sinatra::ContentFor
    # Adds support for session based flash messages.
    enable :sessions
    register Sinatra::Flash

    # Use the framework's logger.
    use Rack::CommonLogger, env.logger

    # Attach helpers.
    helpers Automation::DatabaseHelpers, Automation::DateTimeHelpers, Automation::RunResultHelpers,
            Automation::SiteHelpers, Automation::TestResultHelpers, Automation::CacheHelpers,
            Automation::DiffHelpers, Automation::RunResultHtmlHelpers

    # Debugging information.
    disable :logging
    enable :dump_errors
    # Get the configuration entries from the config manager and apply them now.
    set :port, config_manager['web.port']
    set :bind, config_manager['web.host']
    set :environment, config_manager['web.environment']
    set :server, config_manager['web.server']
    set :lock, config_manager['web.lock']

    # Global application properties.
    set :styles, %w(jquery.dataTables.css jquery.qtip.css site.css)
    set :scripts, %w(jquery.js jquery-ui.js jquery.dataTables.js jquery.form.js jquery.qtip.js login.js site.js)

    # App directories (views and public will resolve relative to this).
    set :root, File.dirname(__FILE__)

  end

end

require_relative 'controllers/home'
require_relative 'controllers/error'
require_relative 'controllers/run_config'
require_relative 'controllers/run'
