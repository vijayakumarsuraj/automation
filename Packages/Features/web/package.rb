# Packages the Web feature.

require 'automation/packages/feature_package'

module Automation::Web

  class Package < Automation::FeaturePackage

    def initialize
      super('web')
    end

    private

    # Defines this package.
    def define
      bin('bin', 'web.bat')

      super
    end

  end

end

register_package('web', __FILE__, Automation::Web::Package)
