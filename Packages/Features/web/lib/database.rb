#
# Suraj Vijayakumar
# 22 Mar 2013
#

require 'automation/core/database'

class Automation::WebDatabase < Automation::Database

  require_relative 'database/models'

  # Update the database schema to the specified version.
  #
  # @param [Integer] version the version to migrate to. If nil, migrates to the latest version.
  def migrate(version = nil)
    @logger.fine('Running web migrations...')
    super(File.join(Automation::FRAMEWORK_ROOT, Automation::FET_DIR, 'web/database/migrations'), version)
  end

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
