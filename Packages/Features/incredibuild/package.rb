# Packages the IncrediBuild feature.

require 'automation/packages/feature_package'

module Automation

  class IncredibuildPackage < Automation::FeaturePackage

    private

    # Defines this package.
    def define
      self.name = 'incredibuild'

      lib('lib', 'runner.rb')
      conf('conf', 'incredibuild.yaml')
      bin('bin', 'incredibuild.bat')
      
      super
    end

  end

  remove_const(:PACKAGE_CLASS) if const_defined?(:PACKAGE_CLASS)
  const_set(:PACKAGE_CLASS, Automation::IncredibuildPackage)

end