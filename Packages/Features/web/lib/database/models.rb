#
# Suraj Vijayakumar
# 20 Mar 2013
#

# The base class for all Web database models.
class Automation::WebDatabase::BaseModel < Automation::Database::BaseModel
  self.table_name_prefix = 'web_'
  self.abstract_class = true
end

require_relative 'models/user'
