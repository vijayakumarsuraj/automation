# Packages the Excel feature.

require 'automation/packages/feature_package'

module Automation

  class ExcelPackage < Automation::FeaturePackage

    private

    # Defines this package.
    def define
      self.name = 'excel'

      lib('lib', 'excel_data.rb', 'excel_methods.rb')
      lib('lib', 'macros')
      conf('conf', 'excel.yaml')

      super
    end

  end

  remove_const(:PACKAGE_CLASS) if const_defined?(:PACKAGE_CLASS)
  const_set(:PACKAGE_CLASS, Automation::ExcelPackage)

end