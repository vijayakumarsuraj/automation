#
# Suraj Vijayakumar
# 31 Oct 2014
#

require 'webdriver/element_wrapper'

require 'automation/core/component'

module Automation

  module Webdriver

    # Represents a web page.
    class Page < Automation::Component

      # The page is basically a wrapper around the browser.
      include Automation::Webdriver::ElementWrapper

      # The browser that is running - same as 'element'.
      attr_reader :browser
      # Access to this page's query string. These are added to the page's path and will be picked up when 'navigate_to' is called.
      attr_reader :query

      # New page.
      #
      # @param [String] path
      def initialize(path)
        @path = (path.length > 0 ? "/#{path}" : path)
        @element = @browser = environment.browser
        @query = {}
      end

      # Builds the relative path to this page (including any query parameters).
      def path
        query_parts = []
        @query.each_pair { |key, value| query_parts << "#{key}=#{URI.escape(value)}" }
        query_parts.length > 0 ? "#{@path}?#{query_parts.join('&')}" : @path
      end

    end

  end

end