# Packages the SVN feature.

require 'automation/packages/feature_package'

module Automation

  class SvnPackage < Automation::FeaturePackage

    private

    # Defines this package.
    def define
      self.name = 'svn'

      lib('lib', 'svn_info.rb', 'svn_log.rb', 'svn_repo.rb')
      conf('conf', 'svn.yaml')

      super
    end

  end

  remove_const(:PACKAGE_CLASS) if const_defined?(:PACKAGE_CLASS)
  const_set(:PACKAGE_CLASS, Automation::SvnPackage)

end