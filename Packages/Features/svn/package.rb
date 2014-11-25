# Packages the SVN feature.

require 'automation/packages/feature_package'

module Automation::Svn

  class Package < Automation::FeaturePackage

    def initialize
      super('svn')
    end

    private

    # Defines this package.
    def define
      super
    end

  end

end

register_package('svn', __FILE__, Automation::Svn::Package)
