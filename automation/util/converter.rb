#
# Suraj Vijayakumar
# 09 Jan 2013
#

module Automation

  # Collection of convenience methods for converting data from one format to another.
  module Converter

    # Convenience method to converts the number of days to a duration,
    # since DateTime - DateTime returns a Rational that represents the number of days.
    #
    # @param days [Float]
    # @return [Float]
    def self.days_to_duration(days)
      seconds_to_duration(days * 86400)
    end

    # Converts the number of seconds to a duration (i.e. 60s to 1m, or 500s to 8m 20s, or 3650s to 1h 0m 50s, etc...)
    #
    # @param seconds [Float]
    # @return [String]
    def self.seconds_to_duration(seconds)
      h = m = nil
      # Extract number of hours.
      if seconds >= 3600
        h = (seconds / 3600).floor
        m = 0
        seconds = seconds - (h * 3600)
      end
      # Extract number of minutes.
      if seconds >= 60
        m = (seconds / 60).floor
        seconds = seconds - (m * 60)
      end
      # Whatever is left is the number of seconds.

      return '%dh:%dm:%ds' % [h, m, seconds] if not h.nil? and h > 0
      return '%dm:%ds' % [m, seconds] if not m.nil? and m > 0
      return '%ds' % [seconds]
    end

    # Converts the specified number to a string delimited by the specified delimiter.
    def self.to_number_with_delimiter(number, delimiter)
      # Need to separate out the decimal part of the number first.
      number = number.to_s
      number, decimal = number.split('.')
      # Then delimit the number part.
      number = number.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
      # Join the decimal part unless it was nil.
      decimal.nil? ? number : "#{number}.#{decimal}"
    end

    # Converts all '/' to '\' in the specified path.
    #
    # @param path [String]
    # @return [String]
    def self.to_windows_path(path)
      path.gsub('/', "\\")
    end

    # Converts all '\' to '/' in the specified path.
    #
    # @param path [String]
    # @return [String]
    def self.to_unix_path(path)
      path.gsub("\\", '/')
    end

    # Converts an array into a string that can be used to call command line programs.
    # All arguments that contain spaces are wrapped in quotes.
    def self.to_command_line_args(array)
      array.map { |item| (item.kind_of?(String) and item.index(' ')) ? "\"#{item}\"" : item }.join(' ')
    end

  end

end