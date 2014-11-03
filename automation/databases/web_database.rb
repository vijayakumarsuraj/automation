#
# Suraj Vijayakumar
# 22 Mar 2013
#

require 'automation/core/database'

module Automation

  # Web database. Stores information relating to how the results data is displayed.
  class WebDatabase < Database

    require_relative 'web_database/models'

    # Get the user identified by the specified name.
    #
    # @param [String] name
    # @return [Automation::WebDatabase::User]
    def get_user(name)
      User.where(username: name).first
    end

    # Get the user for the specified id.
    #
    # @param [String] user_id
    # @return [Automation::WebDatabase::User]
    def find_user(user_id)
      User.find(user_id)
    rescue
      nil
    end

    private

    # The base model for the web database.
    def base_model
      BaseModel
    end

  end

end
