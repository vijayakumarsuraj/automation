#
# Suraj Vijayakumar
# 11 Nov 2014
#

module Automation

  # The WebApp application.
  # This file contains the routes for the allure pages.
  class WebApp < Sinatra::Application

    get '/allure/run/:run_name/*' do |run_name, path|
      # Generate the Allure report if required.
      cached_dir = cache_extract_dir(run_name, 'allure')
      index = File.join(cached_dir, 'index.html')
      unless File.exist?(index)
        @logger.info('Generating allure report...')
        allure_generate_report(cached_dir)
      end
      # Serve the required file.
      send_file(File.join(cached_dir, path))
    end

  end

end
