# Packages the WebDriver feature.

require 'automation/packages/feature_package'

module Automation

  class WebdriverPackage < Automation::FeaturePackage

    private

    # Defines this package.
    def define
      self.name = 'webdriver'

      lib('lib', 'page.rb', 'test.rb', 'Gemfile')
      conf('conf', 'webdriver.yaml')

      super
    end

  end

  remove_const(:PACKAGE_CLASS) if const_defined?(:PACKAGE_CLASS)
  const_set(:PACKAGE_CLASS, Automation::WebdriverPackage)

end