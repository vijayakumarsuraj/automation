#
# Suraj Vijayakumar
# 03 Nov 2014
#

require 'allure-ruby-adaptor-api'

# Monkey patch the adaptor.
module AllureRubyAdaptorApi

  class Builder

    # The allure adaptor uses 'puts' to write stuff to the console.
    # We redirect this to a logger.
    def self.puts(string)
      if @logger.nil?
        @logger = Logging::Logger[self]
        @logger.level = Automation::Runtime.instance.config_manager['allure.logging.level']
      end

      @logger.fine(string)
    end

  end

end
