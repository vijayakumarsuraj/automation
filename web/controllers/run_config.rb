#
# Suraj Vijayakumar
# 18 Mar 2013
#

module Automation

  # The WebApp application.
  # This file contains the routes for the pages related to run configs.
  class WebApp < Sinatra::Application

    # Gets the run configuration for the specified application and config name.
    #
    # @return [ResultsDatabase::RunConfig]
    def get_run_config(application_name, config_name)
      application = ResultsDatabase::Application.where(application_name: application_name).first
      raise WebError.new("Sorry, but we could not find any results for '#{application_name}'!") if application.nil?

      run_config = ResultsDatabase::RunConfig.where(config_name: config_name, application_id: application).first
      raise WebError.new("Sorry, but we could not find any results for '#{application_name}/#{config_name}'!") if run_config.nil?

      run_config
    end

    # RunConfig pages.
    get '/config/:application_name/:config_name/:page_name.html' do |application_name, config_name, page_name|
      raise Sinatra::NotFound.new unless view_exist?("run_config/#{page_name}")

      @header[:page_name] = "#{page_name}.html"
      @header[:page_title] = "#{config_name} :: Automation Results"

      @content[:header_text] = "Automation Results - #{config_name}"
      @content[:header_crumbs][:run_config] = {display: "#{application_name} -- #{config_name}"}

      @content[:run_config] = get_run_config(application_name, config_name)
      haml :"run_config/#{page_name}", format: :html5
    end

    # Test summary page for a particular run config.
    get '/config/:application_name/:config_name/test/:test_name/:page_name.html' do |application_name, config_name, test_name, page_name|
      raise Sinatra::NotFound.new unless view_exist?("run_config/test/#{page_name}")

      @header[:page_name] = "#{page_name}.html"
      @header[:page_title] = "#{test_name} :: #{config_name} :: Automation Results"

      @content[:header_text] = "Automation Results - #{config_name} - #{test_name}"
      @content[:header_crumbs][:run_config] = {display: "#{application_name} -- #{config_name}", href: link('config', application_name, config_name, 'index.html')}
      @content[:header_crumbs][:test] = {display: test_name}

      run_config = get_run_config(application_name, config_name)
      tests = ResultsDatabase::Test.where(test_name: test_name, run_config_id: run_config)

      @content[:test] = tests.first
      @content[:run_config] = run_config
      haml :"run_config/test/#{page_name}", format: :html5
    end

  end

end