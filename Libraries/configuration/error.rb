#
# Suraj Vijayakumar
# 06 Dec 2012
#

module Configuration

  # General configuration error.
  class ConfigurationError < RuntimeError
  end

  # Raised when interpolation fails.
  class InterpolationError < ConfigurationError
  end

  # Raised when a key provided to a configuration is invalid.
  class KeyError < ConfigurationError
  end

end