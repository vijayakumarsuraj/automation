# Packages the Ant feature.

require 'automation/packages/feature_package'

module Automation

  class RspecPackage < Automation::FeaturePackage

    def initialize
      super('rspec')
    end

    private

    # Defines this package.
    def define
      super
    end

  end

  remove_const(:PACKAGE_CLASS) if const_defined?(:PACKAGE_CLASS)
  const_set(:PACKAGE_CLASS, Automation::RspecPackage)

end