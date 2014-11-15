# Packages the Web feature.

require 'automation/packages/feature_package'

module Automation

  class WebPackage < Automation::FeaturePackage

    def initialize
      super('web')
    end

    private

    # Defines this package.
    def define
      bin('bin', 'web.bat')

      super
    end

  end

  remove_const(:PACKAGE_CLASS) if const_defined?(:PACKAGE_CLASS)
  const_set(:PACKAGE_CLASS, Automation::WebPackage)


end