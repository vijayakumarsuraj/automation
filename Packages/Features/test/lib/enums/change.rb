#
# Suraj Vijayakumar
# 20 May 2013
#

require 'automation/core/enum'

module Automation::Test

  # Represents a change in a result.
  class Change < Automation::Enum

    # Indicates that a test was added.
    TestAdded = create(0)
    # Indicates that a test was removed.
    TestRemoved = create(1)
    # Indicates that a test has started failing.
    TestStartedFailing = create(2)
    # Indicates that a test has started passing.
    TestStartedPassing = create(3)
    # Indicates that a test that was failing is now failing for a different reason.
    TestChangedFailure = create(4)

  end

end
