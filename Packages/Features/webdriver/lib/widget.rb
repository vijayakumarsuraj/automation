#
# Suraj Vijayakumar
# 31 Oct 2014
#

require 'webdriver/wraps_element'

require 'automation/core/component'

module Automation::Webdriver

  # Represents a widget on a page.
  # Basically a wrapper around an HTML element.
  class Widget < Automation::Component

    # Basically a wrapper around an element.
    include Automation::Webdriver::WrapsElement

    # The root element wrapped by this part. Same as 'element'.
    alias root element
    # The page this part belongs to.
    attr_reader :page
    # The browser that is running.
    attr_reader :browser

    # New page part.
    #
    # @param [Watir::Element] root
    # @param [Automation::Webdriver::Page] page
    def initialize(root, page)
      super()

      @element = root
      @browser = page.browser
      @page = page
    end

  end

end
