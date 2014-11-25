# Packages the Excel feature.

require 'automation/packages/feature_package'

module Automation::Excel

  class Package < Automation::FeaturePackage

    def initialize
      super('excel')
    end

    private

    # Defines this package.
    def define
      super
    end

  end

end

register_package('excel', __FILE__, Automation::Excel::Package)
