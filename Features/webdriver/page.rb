#
# Suraj Vijayakumar
# 31 Oct 2014
#

require 'automation/core/component'

module Automation

  module Webdriver

    # Represents a web page.
    class Page < Automation::Component

      # New page.
      def initialize(browser)
        @browser = browser
      end

    end

  end

end