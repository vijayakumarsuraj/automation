#
# Suraj Vijayakumar
# 11 Nov 2014
#

require_relative '../controllers/allure'
require_relative '../helpers/allure_helpers'

module Automation

  class WebApp < Sinatra::Application

    # Allure specific helper methods.
    helpers Automation::Allure::Helpers

  end

end
