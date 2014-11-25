# Packages the Ant feature.

require 'automation/packages/feature_package'

module Automation::Ant

  class Package < Automation::FeaturePackage

    def initialize
      super('ant')
    end

    private

    # Defines this package.
    def define
      bin('bin', 'ant.bat')

      super
    end

  end

end

register_package('ant', __FILE__, Automation::Ant::Package)
