#
# Suraj Vijayakumar
# 31 Oct 2014
#

require 'webdriver/wraps_element'

require 'automation/core/component'

module Automation::Webdriver

  # Represents a web page.
  class Page < Automation::Component

    # The page is basically a wrapper around the browser.
    include Automation::Webdriver::WrapsElement

    # The browser that is running - same as 'element'.
    alias browser element
    # Access to this page's query string. These are added to the page's path and will be picked up when 'navigate_to' is called.
    attr_reader :query

    # New page.
    #
    # @param [String] path
    def initialize(path = '', query = {})
      @path = (path.length > 0 ? "/#{path}" : path)
      @element = runtime.browser
      @query = query
    end

    # Opens this page using the current browser.
    def open
      raise NotImplementedError.new("Method 'open' not implemented by '#{self.class.name}'")
    end

    # Builds the relative path to this page (including any query parameters).
    def path
      query_parts = []
      @query.each_pair { |key, value| query_parts << "#{key}=#{URI.escape(value)}" }
      query_parts.length > 0 ? "#{@path}?#{query_parts.join('&')}" : @path
    end

    # Gets the title of this page - i.e. browser.title.
    #
    # @return [String]
    def title
      browser.title
    end

  end

end
