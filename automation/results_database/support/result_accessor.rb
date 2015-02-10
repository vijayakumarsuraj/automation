#
# Suraj Vijayakumar
# 20 May 2013
#

class Automation::ResultsDatabase < Automation::Database

  # Provides a custom accessor for the result column.
  module ResultAccessor

    # Updates the result of this result.
    #
    # @param [Automation::Result] new_result the new result.
    def result=(new_result)
      write_attribute(:result, new_result.value)
    end

    # Gets the result of this result.
    #
    # @return [Automation::Result] the current result.
    def result
      Automation::Result.from_value(read_attribute(:result))
    end

  end

end
