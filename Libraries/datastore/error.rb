#
# Suraj Vijayakumar
# 07 May 2014
#

require 'util/chained_error'

module DataStore

  # Corrupted index related errors.
  class IndexError < RuntimeError

    include Util::ChainedError

  end

end
