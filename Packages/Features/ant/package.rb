# Packages the Ant feature.

require 'automation/packages/feature_package'

module Automation

  class AntPackage < Automation::FeaturePackage

    def initialize
      super('ant')
    end

    private

    # Defines this package.
    def define
      bin('bin', 'ant.bat')
      
      super
    end

  end

  remove_const(:PACKAGE_CLASS) if const_defined?(:PACKAGE_CLASS)
  const_set(:PACKAGE_CLASS, Automation::AntPackage)

end