# Packages the WebDriver feature.

require 'automation/packages/feature_package'

module Automation::Webdriver

  class Package < Automation::FeaturePackage

    def initialize
      super('webdriver')
    end

    private

    # Defines this package.
    def define
      super
    end

  end

end

register_package('webdriver', __FILE__, Automation::Webdriver::Package)
