#
# Suraj Vijayakumar
# 16 Jan 2014
#

require 'openssl'

require 'automation/databases/web_database'

module Automation

  class WebDatabase < Database

    # Represents a user.
    class User < BaseModel

      # Check if the specified password matches the password saved in the database.
      #
      # @param [String] provided
      # @return [Boolean]
      def password_correct?(provided)
        Digest::SHA2.hexdigest(salt + provided).eql?(password)
      end

    end

  end

end
