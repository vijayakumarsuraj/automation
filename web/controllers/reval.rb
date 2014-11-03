#
# Suraj Vijayakumar
# 03 Dec 2013
#

module Automation

  # The WebApp application.
  # This file contains the routes for the reval pages.
  class WebApp < Sinatra::Application

    get '/reval/portfolio/:portfolio/:page_name.html' do |portfolio, page_name|
      raise Sinatra::NotFound unless view_exist?("reval/portfolio/#{page_name}")

      haml :"reval/portfolio/#{page_name}", format: :html5
    end

    get '/reval/run/:run_name/risk/:task_id/risks.html' do |run_name, task_id|
      page_name = 'risks'
      view_name = :"reval/run/#{page_name}"
      raise Sinatra::NotFound unless view_exist?(view_name)

      run_result = @results_database.get_run_result(run_name)
      raise WebError.new("Sorry, but we could not find any results for '#{run_name}'!") if run_result.nil?

      task_result = @results_database.find_task_result(task_id)
      raise WebError.new("Sorry, but we could not find task '#{task_id}'!") if task_result.nil?

      agg_risks = @reval_database.get_agg_risks(task_result)

      @header[:page_name] = "#{page_name}.html"
      @header[:page_title] = "#{run_name} :: Aggregate Risks"
      @header[:nav_disabled] = true
      @header[:header_links_disabled] = true

      @content[:header_text] = "Aggregate Risks - #{run_name}"

      run_config = run_result.run_config
      config_name = run_config.config_name
      application_name = run_config.application.application_name
      @content[:header_crumbs][:run_config] = {display: "#{application_name} -- #{config_name}", href: link('config', application_name, config_name, 'index.html')}
      @content[:header_crumbs][:run] = {display: run_name, href: link('run', run_name, 'index.html')}
      @content[:header_crumbs][:agg_risks] = {display: 'Aggregate Risks'}

      @content[:run_result] = run_result
      @content[:task_result] = task_result
      @content[:agg_risks] = agg_risks
      haml view_name, format: :html5
    end

    get '/reval/run/:run_name/risk/:task_id/:agg_id/deals.html' do |run_name, task_id, agg_id|
      page_name = 'deals'
      view_name = :"reval/run/#{page_name}"
      raise Sinatra::NotFound unless view_exist?(view_name)

      run_result = @results_database.get_run_result(run_name)
      raise WebError.new("Sorry, but we could not find any results for '#{run_name}'!") if run_result.nil?

      task_result = @results_database.find_task_result(task_id)
      raise WebError.new("Sorry, but we could not find task '#{task_id}'!") if task_result.nil?

      agg_risk = @reval_database.find_agg_risk(agg_id)

      @header[:page_name] = "#{page_name}.html"
      @header[:page_title] = "#{run_name} :: #{agg_risk.portfolio} :: Deal Risks"
      @header[:nav_disabled] = true
      @header[:header_links_disabled] = true

      @content[:header_text] = "Deal Risks - #{agg_risk.portfolio} - #{run_name}"

      run_config = run_result.run_config
      config_name = run_config.config_name
      application_name = run_config.application.application_name
      @content[:header_crumbs][:run_config] = {display: "#{application_name} -- #{config_name}", href: link('config', application_name, config_name, 'index.html')}
      @content[:header_crumbs][:run] = {display: run_name, href: link('run', run_name, 'index.html')}
      @content[:header_crumbs][:agg_risks] = {display: 'Aggregate Risks', href: link('reval/run', run_name, 'risk', task_id, 'risks.html')}
      @content[:header_crumbs][:deal_risks] = {display: agg_risk.portfolio}

      @content[:run_result] = run_result
      @content[:task_result] = task_result
      @content[:agg_risk] = agg_risk
      @content[:deal_risks] = agg_risk.deal_risks
      haml view_name, format: :html5
    end

    get '/reval/run/:run_name/diff/:diff_id/risks.html' do |run_name, diff_id|
      page_name = 'risks'
      view_name = :"reval/run/diff/#{page_name}"
      raise Sinatra::NotFound unless view_exist?(view_name)

      run_result = @results_database.get_run_result(run_name)
      raise WebError.new("Sorry, but we could not find any results for '#{run_name}'!") if run_result.nil?

      diff = @reval_database.find_diff(diff_id)
      raise WebError.new("Sorry, but we could not find diff '#{diff_id}'!") if diff.nil?

      @header[:page_name] = "#{page_name}.html"
      @header[:page_title] = "#{run_name} :: Aggregate Diffs"
      @header[:nav_disabled] = true
      @header[:header_links_disabled] = true

      @content[:header_text] = "Aggregate Diffs - #{run_name}"

      run_config = run_result.run_config
      config_name = run_config.config_name
      application_name = run_config.application.application_name
      @content[:header_crumbs][:run_config] = {display: "#{application_name} -- #{config_name}", href: link('config', application_name, config_name, 'index.html')}
      @content[:header_crumbs][:run] = {display: run_name, href: link('run', run_name, 'index.html')}
      @content[:header_crumbs][:agg_diffs] = {display: 'Aggregate Diffs'}

      @content[:run_result] = run_result
      @content[:diff] = diff
      @content[:base_task_result] = diff.base
      @content[:test_task_result] = diff.test
      haml view_name, format: :html5
    end

    get '/reval/run/:run_name/diff/:diff_id/deals.html' do |run_name, diff_id|
      page_name = 'deals'
      view_name = :"reval/run/diff/#{page_name}"
      raise Sinatra::NotFound unless view_exist?(view_name)

      run_result = @results_database.get_run_result(run_name)
      raise WebError.new("Sorry, but we could not find any results for '#{run_name}'!") if run_result.nil?

      agg_diff = @reval_database.find_agg_diff(diff_id)
      raise WebError.new("Sorry, but we could not find diff '#{diff_id}'!") if agg_diff.nil?

      deal_diffs = @reval_database.get_deal_diffs(agg_diff.base, agg_diff.test)

      @header[:page_name] = "#{page_name}.html"
      @header[:page_title] = "#{run_name} :: Deal Diffs"
      @header[:nav_disabled] = true
      @header[:header_links_disabled] = true

      @content[:header_text] = "Deal Diffs - #{run_name}"

      run_config = run_result.run_config
      config_name = run_config.config_name
      application_name = run_config.application.application_name
      @content[:header_crumbs][:run_config] = {display: "#{application_name} -- #{config_name}", href: link('config', application_name, config_name, 'index.html')}
      @content[:header_crumbs][:run] = {display: run_name, href: link('run', run_name, 'index.html')}
      @content[:header_crumbs][:agg_diffs] = {display: 'Aggregate Diffs', href: link('reval/run', run_name, 'diff', agg_diff.diff_id, 'risks.html')}
      @content[:header_crumbs][:deal_diffs] = {display: 'Deal Diffs'}

      @content[:run_result] = run_result
      @content[:base_agg_risk] = agg_diff.base
      @content[:test_agg_risk] = agg_diff.test
      @content[:deal_diffs] = deal_diffs
      haml view_name, format: :html5
    end

  end

end
