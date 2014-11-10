# Packages the Ant feature.

require 'automation/packages/feature_package'

module Automation

  class AntPackage < Automation::FeaturePackage

    private

    # Defines this package.
    def define
      self.name = 'ant'

      lib('lib', 'runner.rb')
      conf('conf', 'ant.yaml')
      bin('bin', 'ant.bat')
      
      super
    end

  end

  remove_const(:PACKAGE_CLASS) if const_defined?(:PACKAGE_CLASS)
  const_set(:PACKAGE_CLASS, Automation::AntPackage)

end