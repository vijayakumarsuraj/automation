# Packages the TeamCity feature.

require 'automation/packages/feature_package'

module Automation

  class TeamcityPackage < Automation::FeaturePackage

    private

    # Defines this package.
    def define
      self.name = 'teamcity'

      lib('lib', 'observer.rb')
      conf('conf', 'teamcity.yaml')

      super
    end

  end

  remove_const(:PACKAGE_CLASS) if const_defined?(:PACKAGE_CLASS)
  const_set(:PACKAGE_CLASS, Automation::TeamcityPackage)

end