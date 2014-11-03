#
# Suraj Vijayakumar
# 14 Mar 2013
#

module Util

  # Include into errors to support changed errors.
  module ChainedError

    # New concurrency error.
    #
    # @param [String] message the message.
    # @param [StandardError] cause the nested cause of the error.
    def initialize(message = nil, cause = nil)
      super(message)

      @cause = cause
    end

    # Overridden to return the message associated with the nested exception also.
    def message
      @cause.nil? ? super : "#{super} (cause: #{@cause.message})"
    end

    # Update the backtrace to include the nested exception's back trace also.
    def set_backtrace(bt)
      if @cause
        # We remove all lines of the nested exception's backtrace that intersect with
        # this exception's backtrace.
        @cause.backtrace.reverse.each { |line| bt.last == line ? bt.pop : break }
        # Add the nested exception's message and back trace to this exception's backtrace.
        bt << "cause: #{@cause} (#{@cause.class.name})"
        bt.concat @cause.backtrace
      end
      #
      super bt
    end

  end

end