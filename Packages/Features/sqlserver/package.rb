# Packages the SQL Server feature.

require 'automation/packages/feature_package'

module Automation::SqlServer

  class Package < Automation::FeaturePackage

    def initialize
      super('sqlserver')
    end

    private

    # Defines this package.
    def define
      super
    end

  end

end

register_package('sqlserver', __FILE__, Automation::SqlServer::Package)
