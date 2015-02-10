#
# Suraj Vijayakumar
# 25 Nov 2014
#

require 'watir-webdriver'

module Watir

  class Element

    # Returns a list of the CSS classes of this element.
    #
    # @return [Array<String>]
    def classes
      attribute_value('class').split(' ')
    end

  end

end