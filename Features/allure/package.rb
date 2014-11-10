# Packages the Allure feature.

require 'automation/packages/feature_package'

module Automation

  class AllurePackage < Automation::FeaturePackage

    private

    # Defines this package.
    def define
      self.name = 'allure'

      lib('lib', 'builder.rb', 'observer.rb', 'service.rb', 'Gemfile')
      lib('lib', 'bin', 'lib')
      conf('conf', 'allure.yaml')

      super
    end

  end

  remove_const(:PACKAGE_CLASS) if const_defined?(:PACKAGE_CLASS)
  const_set(:PACKAGE_CLASS, Automation::AllurePackage)


end