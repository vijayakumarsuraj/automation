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

require 'web/helpers/cache_helper'
require 'web/helpers/database_helpers'
require 'web/helpers/date_time_helpers'
require 'web/helpers/diff_helpers'
require 'web/helpers/run_result_helpers'
require 'web/helpers/run_result_html_helpers'
require 'web/helpers/site_helpers'
require 'web/helpers/test_result_helpers'

module Automation

  class WebError < RuntimeError
  end

  # The WebApp application.
  class WebApp < Sinatra::Application

    include Automation::Kernel

    # Static content types
    STATIC_MIME_TYPES = {'.out' => 'text/plain', '.bench' => 'text/plain', '.xml' => 'text/xml',
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
    set :port, config_manager['mode.web.port']
    set :bind, config_manager['mode.web.host']
    set :environment, config_manager['mode.web.environment']
    set :server, config_manager['mode.web.server']
    set :lock, config_manager['mode.web.lock']

    # Global application properties.
    set :styles, %w(jquery.dataTables.css jquery.qtip.css site.css)
    set :scripts, %w(jquery.js jquery-ui.js jquery.dataTables.js jquery.form.js jquery.qtip.js login.js site.js)

    # App directories.
    set :root, File.join(FRAMEWORK_ROOT, 'web')
    set :views, %w(views)

    # Application bootstraps.
    FileUtils.cd(File.join(config_manager['root_directory'], 'web/applications')) do
      Dir.glob('*') do |application|
        env.logger.info("Initialising application '#{application}'...")
        require File.expand_path(File.join(application, 'init.rb'))
        settings.views << "applications/#{application}/views"
      end
    end

    # Special helper for the views array.
    helpers do
      def find_template(views, name, engine, &block)
        root = settings.root
        Array(views).each { |v| super(File.join(root, v), name, engine, &block) }
      end
    end
  end

end

require 'web/controllers/home'
require 'web/controllers/error'
require 'web/controllers/run_config'
require 'web/controllers/run'
