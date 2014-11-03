#
# Suraj Vijayakumar
# 20 Mar 2013
#

# The base class for all Web database models.
class Automation::WebDatabase::BaseModel < ActiveRecord::Base
end

Automation::WebDatabase::BaseModel.abstract_class = true

require_relative 'models/user'
