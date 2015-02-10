#
# Suraj Vijayakumar
# 13 Mar 2013
#

require 'util/chained_error'

module Automation

  class Error < RuntimeError
    include Util::ChainedError
  end

  # Raised when an error is encountered during parsing the command line.
  class CommandLineError < Automation::Error
  end

  # Raised when a configuration value is invalid.
  class ConfigurationError < Automation::Error
  end

  # Raised when data could not be queried from the results database.
  class DataError < Automation::Error
  end

  # General error raised during execution.
  class ExecutionError < Automation::Error
  end

end
