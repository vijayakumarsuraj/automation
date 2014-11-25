# Packages the TeamCity feature.

require 'automation/packages/feature_package'

module Automation::Teamcity

  class Package < Automation::FeaturePackage

    def initialize
      super('teamcity')
    end

    private

    # Defines this package.
    def define
      super
    end

  end

end

register_package('teamcity', __FILE__, Automation::Teamcity::Package)
