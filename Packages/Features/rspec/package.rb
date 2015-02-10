# Packages the Ant feature.

require 'automation/packages/feature_package'

module Automation::Rspec

  class Package < Automation::FeaturePackage

    def initialize
      super('rspec')
    end

    private

    # Defines this package.
    def define
      super
    end

  end

end

register_package('rspec', __FILE__, Automation::Rspec::Package)
