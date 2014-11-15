# Packages the IncrediBuild feature.

require 'automation/packages/feature_package'

module Automation

  class IncredibuildPackage < Automation::FeaturePackage

    def initialize
      super('incredibuild')
    end

    private

    # Defines this package.
    def define
      bin('bin', 'incredibuild.bat')
      
      super
    end

  end

  remove_const(:PACKAGE_CLASS) if const_defined?(:PACKAGE_CLASS)
  const_set(:PACKAGE_CLASS, Automation::IncredibuildPackage)

end