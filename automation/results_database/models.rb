#
# Suraj Vijayakumar
# 20 Mar 2013
#

# The base class for all Results database models.
class Automation::ResultsDatabase::BaseModel < Automation::Database::BaseModel
  self.table_name_prefix = 'core_'
  self.abstract_class = true
end

require_relative 'support/result_accessor'
require_relative 'support/status_accessor'

require_relative 'models/application'
require_relative 'models/run_config'
require_relative 'models/run_result'
require_relative 'models/task'
require_relative 'models/task_result'
