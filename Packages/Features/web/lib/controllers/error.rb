#
# Suraj Vijayakumar
# 18 Mar 2013
#

module Automation

  # The WebApp application.
  # This file contains the routes for the pages related to run configs.
  class WebApp < Sinatra::Application

    # If the requested resource could not be found.
    not_found do
      @header[:page_title] = 'Page not found :: Automation Results'

      @content[:header_text] = 'Automation Results - Page not found!'
      @content[:header_links] = {}

      haml :'error', format: :html5
    end

    error do
      @header[:page_title] = 'Error :: Automation Results'

      @content[:header_text] = 'Automation Results - Error!'
      @content[:header_links] = {}

      haml :'error', format: :html5
    end

  end

end