#
# Suraj Vijayakumar
# 10 Feb 2015
#

require 'automation/core/task'

require 'test/enums/change'

module Automation

  class Task < Component

    # Feature specific constructor override.
    def initialize_with_test_task
      initialize_without_test_task

      @test_database = @databases['test']
    end

    alias_method_chain :initialize, :test_task

  end

end