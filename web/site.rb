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
require 'web/helpers/phase_two_helpers'
require 'web/helpers/reval_helpers'
require 'web/helpers/run_result_helpers'
require 'web/helpers/run_result_html_helpers'
require 'web/helpers/site_helpers'
require 'web/helpers/test_result_helpers'
require 'web/helpers/westminster_helpers'

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
    environment = Automation.environment
    config_manager = environment.config_manager

    # Add support for the partial and render methods in HAML.
    register Sinatra::Partial
    # Add support for the content_for and yield_content methods.
    helpers Sinatra::ContentFor
    # Adds support for session based flash messages.
    enable :sessions
    register Sinatra::Flash

    # Use the framework's logger.
    use Rack::CommonLogger, environment.logger

    # Attach helpers.
    helpers Automation::DatabaseHelpers, Automation::DateTimeHelpers, Automation::RunResultHelpers,
            Automation::SiteHelpers, Automation::TestResultHelpers, Automation::CacheHelpers,
            Automation::DiffHelpers, Automation::RunResultHtmlHelpers

    # Application specific helpers.
    helpers Automation::RevalHelpers
    helpers Automation::PhaseTwoHelpers
    helpers Automation::WestminsterHelpers

    # Reval specific database.
    environment.databases['reval'] = proc do
      next environment.reval_database if environment.defined?(:reval_database)

      file = File.join(FRAMEWORK_ROOT, APP_DIR, 'reval/Configuration/default.yaml')
      config = Configuration::YamlConfiguration.new(file)
      config_manager.add_configuration('reval', config, 1)
      # Create.
      require 'reval/databases/reval_database'
      environment.save(:reval_database, Automation::Reval::RevalDatabase.new)
      environment.reval_database
    end

    # PhaseTwo specific database.
    environment.databases['phase_two'] = proc do
      next environment.phase_two_database if environment.defined?(:phase_two_database)

      file = File.join(FRAMEWORK_ROOT, APP_DIR, 'phase_two/Configuration/default.yaml')
      config = Configuration::YamlConfiguration.new(file)
      config_manager.add_configuration('phase_two', config, 1)
      # Create.
      require 'phase_two/databases/phase_two_database'
      environment.save(:phase_two_database, Automation::PhaseTwo::PhaseTwoDatabase.new)
      environment.phase_two_database
    end

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
    set :views, %w(views applications)

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
require 'web/controllers/phase_two'
require 'web/controllers/reval'
