#
# Suraj Vijayakumar
# 19 Jan 2015
#

# The base class for all Web database models.
class Automation::TestDatabase::BaseModel < Automation::Database::BaseModel
  self.table_name_prefix = 'test_'
  self.abstract_class = true
end

require_relative 'support/change_accessor'

require_relative 'models/application'
require_relative 'models/change_event'
require_relative 'models/run_config'
require_relative 'models/run_result'
require_relative 'models/test'
require_relative 'models/test_result'
