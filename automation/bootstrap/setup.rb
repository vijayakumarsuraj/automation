#
# Suraj Vijayakumar
# 19 Jul 2013
#

require 'date'
require 'fileutils'
require 'observer'
require 'open3'
require 'optparse'
require 'singleton'
require 'socket'
require 'thread'
require 'tmpdir'
require 'tempfile'
require 'yaml'

require_relative 'environment'
require_relative 'installer'
require_relative 'kernel'
require_relative 'user_settings'

require 'configuration/combined_configuration'

module Automation

  # Raised when setup encounters an error.
  class SetupError < RuntimeError
  end

  class Setup

    # Provides access to core kernel functions.
    include Automation::Kernel

    # Sets up the framework before the first execution.
    #
    # @param [Boolean] force if true, setup is run even if it is not required.
    def self.setup(force = false)
      clean = force && ARGV.include?('--clean')
      skip_env = ARGV.include?('--skip-env')
      options = {force: force, clean: clean, skip_env: skip_env}
      FileUtils.cd(FRAMEWORK_ROOT) { Setup.new.run(options) }
    end

    # New setup class. Should not be instantiated - instead use Setup.setup.
    def initialize
      # Load the setup settings and any user overrides.
      @settings = Configuration::CombinedConfiguration.new
      @settings.load_configuration('default', 'Configuration/setup.yaml')
      @settings.load_configuration('user', 'Configuration/user.yaml')

      @ruby_bin = RbConfig::CONFIG['bindir']
      @install_flag = ".bundle/#{RUBY_VERSION}_#{ruby_platform}.flag"

      # The timestamp values - the installer is run depending on these values.
      @t1 = UserSettings.last_modify_date.to_i
      @t2 = File.mtime('Gemfile').to_i

      @gem_path = File.join(@settings['setup.gem_path'], ruby_platform)
      @mysql_dir = File.join(FRAMEWORK_ROOT, "#{LIB_DIR}/mysql/#{ruby_platform}")

      environment.save(:ruby_bin, @ruby_bin)
      environment.save(:gem_path, @gem_path)
      environment.save(:mysql_dir, @mysql_dir)
      environment.save(:setup_settings, @settings)
    end

    # Run the setup.
    def run(options = {})
      defaults = {force: false, clean: false, skip_env: false}
      options = defaults.merge(options)
      #
      force = options[:force]
      clean = options[:clean]
      skip_env = options[:skip_env]
      #
      clean_bundle if clean
      update_bundler_config
      run_installer if (force || install_required?)
      build_env_bat if force && !skip_env
      update_load_path
    end

    private

    # Builds the env.bat file that will be used by the framework's run script.
    def build_env_bat
      connector_dir = File.join(@mysql_dir, 'lib')
      env = {mysql_lib: to_windows_path(connector_dir)}

      print 'ruby.exe location: '; env[:ruby_bin] = read_path
      print 'python.exe location: '; env[:python_bin] = read_path
      print '7z.exe location: '; env[:zip_bin] = read_path
      print 'wincmp3.exe location: '; env[:compare_bin] = read_path
      puts

      FileUtils.cd(FRAMEWORK_ROOT) { File.write('env.bat', ENV_BAT_TEMPLATE % env) }
    end

    # Cleans all installed gems and the bundler config directory.
    def clean_bundle
      if File.exist?(@gem_path)
        puts "Cleaning gem repository - #{@gem_path}"
        FileUtils.rm_r(@gem_path)
      end
      bundler_dir = '.bundle'
      if File.exist?(bundler_dir)
        puts 'Cleaned bundler directory - .bundle'
        FileUtils.rm_r(bundler_dir)
      end
    end

    # Check to see if this is the first run for the specified Ruby version.
    #
    # @return [Boolean] true if this is the first run, false otherwise.
    def install_required?
      return true unless File.exist?(@install_flag)

      # The file exists, so open it and read the timestamp values.
      # If they match, return false. Otherwise return true.
      File.open(@install_flag, 'rb') do |f|
        ft1, ft2 = f.read(8).unpack('L*')
        return !(ft1 == @t1 && ft2 == @t2)
      end
    end

    # Reads a line of input from the user. The line is treated as a path and converted to use Windows' path
    # separator.
    def read_path
      to_windows_path($stdin.readline.chomp.strip)
    end

    # Runs the installer, if required.
    def run_installer
      Installer.install
      File.open(@install_flag, 'wb') { |f| f.write([@t1, @t2].pack('L*')) }
    end

    # Updates the bundler config file.
    def update_bundler_config
      # Set the bundler config entries.
      set_bundler_config('path', @gem_path)
      set_bundler_config('build.mysql2', "--with-mysql-dir=#{@mysql_dir}")
    end

    # Sets a local bundler configuration.
    #
    # @param [String] key the key.
    # @param [Array<String>] values the values.
    def set_bundler_config(key, *values)
      output, status = popen_capture("#{@ruby_bin}/bundle", 'config', '--local', key, *values)
      if status.exitstatus != 0
        puts output
        raise SetupError.new("'Bundler' error. Please run 'gem install bundler' first.")
      end
    end

    # Converts all '/' to '\' in the specified path.
    #
    # @param path [String]
    # @return [String]
    def to_windows_path(path)
      path.gsub('/', "\\")
    end

    # Update the framework's load path (includes all gems)
    def update_load_path
      require 'bundler'
      Bundler.setup
    end

  end

end

ENV_BAT_TEMPLATE = <<-ENV_BAT
@ECHO OFF

REM Flag to indicate if this file has executed already.
IF DEFINED __ENV__ (GOTO END)
SET __ENV__=TRUE

REM Paths to required applications.
SET RUBY=%{ruby_bin}
SET PYTHON=%{python_bin}
SET ZIP=%{zip_bin}
SET COMPARE=%{compare_bin}
SET MYSQL2=%{mysql_lib}

REM Update the PATH environment variable.
SET PATH=%%RUBY%%;%%PYTHON%%;%%ZIP%%;%%COMPARE%%;%%MYSQL2%%;%%PATH%%

:END
ENV_BAT
