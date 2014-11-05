#
# Suraj Vijayakumar
# 20 Jul 2013
#

require_relative 'kernel'

module Automation

  # Raised when installation encounters an error.
  class InstallationError < RuntimeError
  end

  # Responsible for installing the gems required by the framework.
  class Installer

    # Provides access to core kernel functions.
    include Automation::Kernel

    # Installs the framework for the first run.
    def self.install
      Installer.new.run
    end

    # New installer.
    def initialize
      @ruby_bin = environment.ruby_bin
      @settings = environment.setup_settings
    end

    def run
      puts 'Please wait. Gems are being installed...'
      puts

      install_gems

      puts
    end

    private

    # Attempts to install all required gems.
    def install_gems
      # Excluded groups.
      without = []
      # Validate install paths.
      validate_path(environment.gem_path)
      validate_path(environment.mysql_dir)
      # Install!
      without << '""' if without.length == 0
      system("#{@ruby_bin}/bundle", 'install', '--local', '--no-cache', '--without', *without)
      raise InstallationError.new('Gem installation failed!') unless $?.success?
    end

    # Validate that the specified does not contain spaces.
    # This is required since Ruby's DevKit can't install native extensions to a path with spaces.
    def validate_path(path)
      raise InstallationError.new("Gem installation failed - path '#{path}' contains spaces") if path.include?(' ')
    end

  end

end
