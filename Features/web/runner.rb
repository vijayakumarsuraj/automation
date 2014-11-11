#
# Suraj Vijayakumar
# 11 Feb 2013
#

require 'automation/modes/support'

module Automation

  # Standard mode for hosting run results.
  class Web < SupportMode

    module CommandLineOptions

      # Method for creating the web database option.
      def option_web_database
        block = proc { |database| save_option_value('database.web_database.database_id', database); propagate_option('--web-database', database) }
        @cl_parser.on('--web-database ID', 'Specify the id of the database to use.',
                      'If skipped, the default specified for the mode is used.', &block)

        block = proc { save_option_value('database.web_database.migrate', true) }
        @cl_parser.on('--web-database-migrate', 'Drop the database schema and then re-create it (all data will be lost!).', &block)

        block = proc { save_option_value('database.web_database.migrate', false) }
        @cl_parser.on('--web-database-upgrade', 'Try to update the the database schema (the default behaviour).', &block)

        block = proc { |flag| save_option_value('database.web_database.logging', flag); propagate_option("--#{flag ? '' : 'no-'}web-database-logging") }
        @cl_parser.on('--[no-]web-database-logging', 'Enable / disable the logging of database calls (SQL queries, model loading)', &block)
      end

      # Method for creating the deployment options.
      def option_deploy
        block = proc { |flag| save_option_value('web.deploy.enabled', flag) }
        @cl_parser.on('--[no-]web-deploy', 'Enable / disable deployment before starting the web server.', &block)

        block = proc { save_option_value('web.deploy.clean', true) }
        @cl_parser.on('--web-deploy-clean', 'Do a clean deploy. i.e. Delete the deployment folder and re-create it.', &block)

        block = proc { save_option_value('web.deploy_only', true) }
        @cl_parser.on('--web-deploy-only', "Only deploy the web server, don't start it.', 'Ignored if deployment is disabled.", &block)
      end

      # Method for creating the server option.
      def option_server
        block = proc { |environment| save_option_value('web.environment', environment) }
        @cl_parser.on('--web-environment ENV', 'Specify the environment to use (default: development).', &block)

        block = proc { |host| save_option_value('web.host', host) }
        @cl_parser.on('--web-host HOST', 'Specify the host to bind to (default: 127.0.0.1).', &block)

        block = proc { save_option_value('web.lock', true) }
        @cl_parser.on('--web-lock', 'Turn on mutex locking (default: false).', &block)

        block = proc { |port| save_option_value('web.port', port) }
        @cl_parser.on('--web-port PORT', Integer, 'Specify the port to bind to (default: 8080).', &block)

        block = proc { |server| save_option_value('web.server', server) }
        @cl_parser.on('--web-handler HANDLER', 'Specify the Rack handler to use (default: thin).', &block)

        block = proc { |prefix| save_option_value('web.link_prefix', prefix) }
        @cl_parser.on('--web-link-prefix PREFIX', 'Specify the prefix to be used for links.', &block)
      end

    end

    # Include the WebMode specific command line options.
    include Automation::Web::CommandLineOptions

    def initialize
      super

      # Sinatra will be told to use this logger.
      environment.save('logger', @logger)
    end

    private

    def run
      super
      # The first and ONLY place the web database is created and connected to.
      @web_database = load_component(Component::DatabaseType, 'web_database')
      @web_database.connect
      # Migrate (i.e. recreate the db schema) if required.
      migrate = @config_manager['database.web_database.migrate', default: false]
      migrate ? @web_database.migrate! : @web_database.migrate
      @databases['web'] = @web_database
      # Deploy the web files - including any application specific code.
      deploy_directory = @config_manager['web.deploy.directory']
      if @config_manager['web.deploy.enabled']
        @logger.info("Deploying to '#{deploy_directory}'...")
        deploy(deploy_directory, @config_manager['web.deploy.clean'])
        # If only deployment was set, return now.
        return if @config_manager['web.deploy_only']
      end
      # Load the core site.rb file.
      @logger.info('Initialising site...')
      site_rb = File.join(deploy_directory, 'site.rb')
      require site_rb
      # And then each plugin's.
      plugins_directory = File.join(deploy_directory, 'plugins')
      if File.exist?(plugins_directory)
        FileUtils.cd(plugins_directory) do
          Dir.glob('*').each do |plugin|
            @logger.info("Initialising '#{plugin}'...")
            require File.join(plugins_directory, "#{plugin}")
          end
        end
      end
      # Now run!
      @logger.info("Running '#{site_rb}'...")
      WebApp.run!
    end

    # Adds the web specific options.
    def create_mode_options
      option_separator
      option_separator 'Web options:'
      option_web_database
      option_deploy

      option_separator
      option_server
    end

    # Deploys the web code to the specified directory.
    #
    # @param [String] directory
    # @param [Boolean] clean
    def deploy(directory, clean = false)
      # Clean & create the deployment directory if required.
      FileUtils.rm_rf(directory) if clean
      FileUtils.mkdir_p(directory) unless File.exist?(directory)

      # First glob all the files from the web directory.
      web_directory = @config_manager['web.directory']
      core_files = glob_files_to_deploy(web_directory, %w(Gemfile runner.rb))
      # Next glob all the files from each application's web directory.
      app_files = []
      applications_directory = @config_manager['applications_directory']
      FileUtils.cd(applications_directory) do
        Dir.glob('*') do |application|
          app_web_directory = File.join(applications_directory, application, '.web')
          next unless File.exist?(app_web_directory) # Skip if the application doesn't have any web code.
          @logger.debug("Including application '#{application}'")
          app_files += glob_files_to_deploy(app_web_directory)
        end
      end
      # Finally glob all the files from each feature's web directory.
      feature_files = []
      features_directory = @config_manager['features_directory']
      FileUtils.cd(features_directory) do
        Dir.glob('*') do |feature|
          feature_web_directory = File.join(features_directory, feature, '.web')
          next if feature.eql?('web') # Skip the 'web' directory too.
          next unless File.exist?(feature_web_directory) # Skip if the feature doesn't have any web code.
          @logger.debug("Including feature '#{application}'")
          feature_files += glob_files_to_deploy(feature_web_directory)
        end
      end

      # Copy each of the files. Overwriting only those that are newer.
      background(core_files + app_files + feature_files, WAIT_FOR_RESULT) do |dir, file|
        dest = File.join(directory, file)
        src = File.join(dir, file)
        if File.exist?(dest) && (File.mtime(src) <= File.mtime(dest))
          @logger.fine("Skipping '#{src}' - already up to date.")
          next
        end

        @logger.fine("Copying '#{src}' to '#{dest}'...")
        dest_dir = File.dirname(dest)
        FileUtils.mkdir_p(dest_dir) unless File.exist?(dest_dir)
        FileUtils.cp(src, dest)
      end
    end

    # Gets all required files under the specified directory (recursively).
    # Returns an array of arrays. Each row in the array will contain the provided root directory and a path relative to that root.
    #
    # @param [String] root_directory
    # @param [Array<String>] exclude_files
    def glob_files_to_deploy(root_directory, exclude_files = [])
      FileUtils.cd(root_directory) do
        return Dir.glob('**/*.*').reject { |path| exclude_files.include?(path) }.map { |path| [root_directory, path] }
      end
    end

  end

end
