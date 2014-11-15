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
      @logger = Logging::Logger[self] if @logger.nil?
      @logger.fine(string)
    end

  end

end
