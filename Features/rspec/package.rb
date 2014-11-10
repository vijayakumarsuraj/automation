# Packages the Ant feature.

require 'automation/packages/feature_package'

module Automation

  class RspecPackage < Automation::FeaturePackage

    private

    # Defines this package.
    def define
      self.name = 'rspec'

      lib('lib', 'runner.rb')
      conf('conf', 'rspec.yaml')

      super
    end

  end

  remove_const(:PACKAGE_CLASS) if const_defined?(:PACKAGE_CLASS)
  const_set(:PACKAGE_CLASS, Automation::RspecPackage)

end