# Packages the IncrediBuild feature.

require 'automation/packages/feature_package'

module Automation::Incredibuild

  class Package < Automation::FeaturePackage

    def initialize
      super('incredibuild')
    end

    private

    # Defines this package.
    def define
      bin('bin', 'incredibuild.bat')

      super
    end

  end

end

register_package('incredibuild', __FILE__, Automation::Incredibuild::Package)
