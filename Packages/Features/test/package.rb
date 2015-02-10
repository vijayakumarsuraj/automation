# Packages the Web feature.

require 'automation/packages/feature_package'

module Automation::Test

  class Package < Automation::FeaturePackage

    def initialize
      super('test')
    end

    private

    # Defines this package.
    def define
      super
    end

  end

end

register_package('test', __FILE__, Automation::Test::Package)
