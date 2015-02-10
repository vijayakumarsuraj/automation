module Automation::Test
  require_relative 'core/component'
  require_relative 'core/mode'
  require_relative 'core/task'
  require_relative 'core/test'
  require_relative 'core/test_pack'

  require_relative 'assertions/boolean'
  require_relative 'assertions/file'
  require_relative 'assertions/null'
  require_relative 'assertions/operator'

  on_require('automation/modes/runner') { require 'test/modes/runner' }
  on_require('automation/modes/single') { require 'test/modes/single' }
  on_require('automation/modes/support') { require 'test/modes/support' }
end
