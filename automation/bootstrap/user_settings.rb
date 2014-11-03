#
# Suraj Vijayakumar
# 20 Jul 2013
#

module Automation

  # Represents the user settings YAML file.
  class UserSettings

    # Get the modification date time for the user.yaml file.
    def self.last_modify_date
      # Create the default file if one does not exist.
      file = 'Configuration/user.yaml'
      unless File.exist?(file)
        puts 'User settings file not found. Creating empty file...'
        File.open(file, 'w') { |f| f.puts DEFAULT_USER_SETTINGS }
      end
      # Return the modification date-time.
      File.mtime(file)
    end

  end

end

DEFAULT_USER_SETTINGS = <<-USER_SETTINGS
# User specific configuration file
USER_SETTINGS