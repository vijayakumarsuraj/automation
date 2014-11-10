# Packages the Web feature.

require 'automation/packages/feature_package'

module Automation

  class WebPackage < Automation::FeaturePackage

    private

    # Defines this package.
    def define
      self.name = 'web'

      lib('lib', 'database.rb', 'runner.rb', 'site.rb', 'Gemfile')
      lib('lib', 'controllers', 'database', 'helpers', 'public', 'views')
      conf('conf', 'web.yaml')
      bin('bin', 'web.bat')

      super
    end

  end

  remove_const(:PACKAGE_CLASS) if const_defined?(:PACKAGE_CLASS)
  const_set(:PACKAGE_CLASS, Automation::WebPackage)


end