#
# Suraj Vijayakumar
# 08 Dec 2012
#

raise "Unsupported Ruby v#{RUBY_VERSION}! Please use Ruby v2.0.0 or greater." if RUBY_VERSION < '2.0.0'

# Entry point for the framework.

# Sync the output and error streams - so the output is echoed as soon as it is written.
$stdout.sync = true
$stderr.sync = true

# Global constants.
module Automation

  FRAMEWORK_PWD = Dir.pwd
  FRAMEWORK_ROOT = File.expand_path(File.dirname(__FILE__))

  LIB_DIR = 'Libraries'
  APP_DIR = 'Applications'
  FET_DIR = 'Features'

end

$LOAD_PATH.delete('.')
$LOAD_PATH << Automation::FRAMEWORK_ROOT
$LOAD_PATH << File.join(Automation::FRAMEWORK_ROOT, Automation::LIB_DIR)
$LOAD_PATH << File.join(Automation::FRAMEWORK_ROOT, Automation::APP_DIR)
$LOAD_PATH << File.join(Automation::FRAMEWORK_ROOT, Automation::FET_DIR)

# Setup up the framework.
require 'automation/bootstrap/setup'
force = ARGV[0].eql?('setup')
Automation::Setup.setup(force)
if force
  puts 'Setup completed successfully'
  puts "Please review the 'Configuration/user.yaml' file now"
  exit(0)
end

# Load the framework's core components and default configuration.
require 'automation/core'
Automation.load_default_configuration
Automation.configure_logging

# If no arguments were provided, then print a usage message along with all supported application names.
if ARGV.length == 0
  applications = Automation.supported_applications
  puts Automation::FRAMEWORK_TITLE
  puts 'Usage: ruby main.rb <application>-<mode> [options] [tests]'
  puts
  puts 'Supported applications:'
  puts applications.join("\n")
  puts
  puts "Try 'ruby main.rb <application>-modes' for a list of supported modes."
  exit(1)
end

# The application and mode the framework should run.
p1, p2 = ARGV.delete_at(0).split('-', 2)
# If only one value was specified, we treat it as the mode and the application is left blank.
# Otherwise proceed as normal.
if p2.nil?
  application, mode = '', p1
else
  application, mode = Automation.expand_application(p1), p2
end

# If the mode specified was 'modes', we enable the help flag and nil the mode.
# If no mode was specified, we enable the help flag and nil the mode.
# Otherwise a mode has been specified, so we can proceed as normal.
if mode.eql?('modes') || mode.empty?
  show_supported_modes = true
  mode = nil
else
  show_supported_modes = false
end

# Load mode and application specific configuration files.
Automation.load_configurations(application, mode)

# If true, print a usage message along with all supported modes (for the application specified).
if show_supported_modes
  raise 'Cannot show supported modes - no application was specified' if application.empty?

  modes = Automation.supported_modes
  puts Automation::FRAMEWORK_TITLE
  puts "Usage: ruby main.rb #{application}-<mode> [options] [tests]"
  puts
  puts 'Supported modes:'
  puts modes.map { |name, description| '%-10s - %s' % [name, description] }.join("\n")
  puts
  puts "Try 'ruby main.rb #{application}-<mode> --help' for a list of supported options."
  exit(1)
end

# Configure the framework.
Automation.configure(application, mode)
include Automation::Kernel

# Load the required mode and start it.
component = load_component(Automation::Component::ModeType, mode)
component.start

# All done. Shutdown the automation thread pool.
environment.thread_pool.shutdown_now
environment.thread_pool.wait_for(1)

# Exit with the appropriate exit code.
exit(component.result.return_value)
