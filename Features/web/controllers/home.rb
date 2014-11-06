#
# Suraj Vijayakumar
# 18 Mar 2013
#

module Automation

  # The WebApp application.
  # This file contains the routes for the home page.
  class WebApp < Sinatra::Application

    # Executed before each request.
    before do
      @path_info = request.path_info

      @logger = Logging::Logger['Automation::WebApp']
      @config_manager = environment.config_manager
      @results_archive = environment.results_archive
      @databases = environment.databases

      @results_database = @databases.results_database
      @web_database = @databases['web']

      @link_prefix = @config_manager['web.link_prefix', default: '/']
      @link_prefix = "/#{@link_prefix}" unless @link_prefix.start_with?('/')
      @link_prefix = "#{@link_prefix}/" unless @link_prefix.ends_with?('/')

      user_id = session['user']
      @user = user_id.nil? ? nil : @web_database.find_user(user_id)

      @header = {}
      @header[:styles] = [] + settings.styles
      @header[:scripts] = [] + settings.scripts

      @content = {}
      @content[:header_crumbs] = {home: {display: 'Home', href: link('index.html')}}

      @defaults = {}
    end

    # Executed after each request.
    after do
      ActiveRecord::Base.clear_active_connections!
    end

    # Redirect to the index page.
    get '/' do
      redirect link('index.html')
    end

    # Index.
    get '/index.html' do
      @header[:page_name] = 'index.html'
      @header[:page_title] = 'Automation Results'

      @content[:header_text] = 'Automation Results'
      @content[:header_crumbs] = {home: {display: 'Home'}}

      @content[:run_configs] = ResultsDatabase::RunConfig.order('config_name ASC').to_a
      haml :'index', format: :html5
    end

    get '/login.ajax' do
      haml :'ajax/login', layout: false
    end

    post '/logout' do
      session['user'] = nil
      flash[:pass] = 'You are now logged out'
    end

    post '/login' do
      username = params['username']
      password = params['password']
      user = @web_database.get_user(username)

      if user.nil?
        json success: false, message: "User '#{username}' not found."
      elsif user.password_correct?(password)
        session['user'] = user.id
        json success: true
      else
        json success: false, message: 'Password is incorrect'
      end
    end

    # Allows updating server side settings with a 'post' request.
    post '/settings' do
      params.each_pair { |key, value| session[key] = value }
    end

    # Allows updating server side settings with a 'post' request.
    post '/settings/:app_name' do |app_name|
      params.each_pair { |key, value| session["#{app_name}.#{key}"] = value }
    end

  end

end
