#
# Suraj Vijayakumar
# 31 Oct 2014
#

require 'webdriver/element_wrapper'

require 'automation/core/component'

module Automation

  module Webdriver

    # Represents a part of a web page.
    class PagePart < Automation::Component

      # The part is basically a wrapper around an element.
      include Automation::Webdriver::ElementWrapper

      # The element wrapped by this part. Same as 'element'.
      attr_reader :root
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

        @element = @root = root
        @browser = page.browser
        @page = page
      end

    end

  end

end