#
# Suraj Vijayakumar
# 20 Mar 2013
#

# The base class for all Results database models.
class Automation::ResultsDatabase::BaseModel < ActiveRecord::Base
end

Automation::ResultsDatabase::BaseModel.abstract_class = true

require_relative 'support/change_accessor'
require_relative 'support/result_accessor'
require_relative 'support/status_accessor'
require_relative 'support/vcs_type_accessor'

require_relative 'models/application'
require_relative 'models/change_event'
require_relative 'models/run_config'
require_relative 'models/run_result'
require_relative 'models/task'
require_relative 'models/task_result'
require_relative 'models/test'
require_relative 'models/test_result'
require_relative 'models/vcs_repo'
