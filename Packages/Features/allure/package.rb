# Packages the Allure feature.

require 'automation/packages/feature_package'

module Automation::Allure

  class Package < Automation::FeaturePackage

    def initialize
      super('allure')
    end

    private

    # Defines this package.
    def define
      super
    end

  end

end

register_package('allure', __FILE__, Automation::Allure::Package)
