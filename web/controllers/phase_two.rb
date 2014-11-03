#
# Suraj Vijayakumar
# 09 Sep 2014
#

module Automation

  # The WebApp application.
  # This file contains the routes for the reval pages.
  class WebApp < Sinatra::Application

    get '/phase_two/run/:run_name/pv/:task_id/books.html' do |run_name, task_id|
      page_name = 'books'
      view_name = :"phase_two/run/#{page_name}"
      raise Sinatra::NotFound unless view_exist?(view_name)

      run_result = @results_database.get_run_result(run_name)
      raise WebError.new("Sorry, but we could not find any results for '#{run_name}'!") if run_result.nil?

      task_result = @results_database.find_task_result(task_id)
      raise WebError.new("Sorry, but we could not find task '#{task_id}'!") if task_result.nil?

      book_pvs = @phase_two_database.get_book_pvs(task_result)

      # Get the PVs for the previous run and map them against the contract ID.
      previous_book_pvs = {}
      previous_task_result = phase_two_previous_task_result(task_result)
      unless previous_task_result.nil?
        @phase_two_database.get_book_pvs(previous_task_result).each do |book_pv|
          previous_book_pvs[book_pv.portfolio.id] = book_pv
        end
      end

      @header[:page_name] = 'index.html'
      @header[:page_title] = "#{run_name} :: Books"
      @header[:header_links_disabled] = true
      @header[:nav_prefix] = 'run'

      @content[:header_text] = "Books - #{run_name}"

      run_config = run_result.run_config
      config_name = run_config.config_name
      application_name = run_config.application.application_name
      @content[:header_crumbs][:run_config] = {display: "#{application_name} -- #{config_name}", href: link('config', application_name, config_name, 'index.html')}
      @content[:header_crumbs][:run] = {display: run_name, href: link('run', run_name, 'index.html')}
      @content[:header_crumbs][:book_pvs] = {display: 'Book PVs'}

      @content[:run_result] = run_result
      @content[:task_result] = task_result
      @content[:book_pvs] = book_pvs
      @content[:previous_book_pvs] = previous_book_pvs
      haml view_name, format: :html5
    end

    get '/phase_two/run/:run_name/pv/:book_id/contracts.html' do |run_name, book_pv_id|
      page_name = 'contracts'
      view_name = :"phase_two/run/#{page_name}"
      raise Sinatra::NotFound unless view_exist?(view_name)

      run_result = @results_database.get_run_result(run_name)
      raise WebError.new("Sorry, but we could not find any results for '#{run_name}'!") if run_result.nil?

      book_pv = @phase_two_database.find_book_pv(book_pv_id)
      raise WebError.new("Sorry, but we could not find book '#{book_pv_id}'!") if book_pv.nil?
      contract_pvs = book_pv.contract_pvs

      # Get the PVs for the previous run and map them against the contract ID.
      previous_contract_pvs = {}
      previous_book_pv = nil
      previous_task_result = phase_two_previous_task_result(book_pv.task_result)
      unless previous_task_result.nil?
        portfolio = book_pv.portfolio
        previous_book_pv = @phase_two_database.get_book_pv(previous_task_result, portfolio.currency, portfolio.portfolio, portfolio.product)
        unless previous_book_pv.nil?
          previous_book_pv.contract_pvs.each do |contract_pv|
            previous_contract_pvs[contract_pv.contract_id] = contract_pv
          end
        end
      end

      @header[:page_name] = "index.html"
      @header[:page_title] = "#{run_name} :: Contracts"
      @header[:header_links_disabled] = true
      @header[:nav_prefix] = 'run'

      @content[:header_text] = "Contracts - #{run_name}"

      run_config = run_result.run_config
      config_name = run_config.config_name
      application_name = run_config.application.application_name
      @content[:header_crumbs][:run_config] = {display: "#{application_name} -- #{config_name}", href: link('config', application_name, config_name, 'index.html')}
      @content[:header_crumbs][:run] = {display: run_name, href: link('run', run_name, 'index.html')}
      @content[:header_crumbs][:book_pvs] = {display: 'Contract PVs'}

      @content[:run_result] = run_result
      @content[:task_result] = book_pv.task_result
      @content[:book_pv] = book_pv
      @content[:contract_pvs] = contract_pvs
      @content[:previous_book_pv] = previous_book_pv
      @content[:previous_contract_pvs] = previous_contract_pvs
      haml view_name, format: :html5
    end

    get '/phase_two/run/:run_name/diff/:test_result_id/books.html' do |run_name, test_result_id|
      page_name = 'books'
      view_name = :"phase_two/run/diff/#{page_name}"
      raise Sinatra::NotFound unless view_exist?(view_name)

      run_result = @results_database.get_run_result(run_name)
      raise WebError.new("Sorry, but we could not find any results for '#{run_name}'!") if run_result.nil?

      test_result = @results_database.find_test_result(test_result_id)
      raise WebError.new("Sorry, but we could not find the test '#{test_result_id}'!") if test_result.nil?

      v_old = test_result.properties['binaries.version_old']
      v_new = test_result.properties['binaries.version_new']
      task_result_old = phase_two_task_result(v_old, run_result)
      task_result_new = phase_two_task_result(v_new, run_result)
      book_pv_diffs = @phase_two_database.get_book_diffs(task_result_old, task_result_new)

      # Get the diffs for the previous run and map them against the portfolio ID.
      previous_book_pv_diffs = {}
      previous_task_result_old = phase_two_previous_task_result(task_result_old)
      previous_task_result_new = phase_two_previous_task_result(task_result_new)
      unless previous_task_result_old.nil? || previous_task_result_new.nil?
        @phase_two_database.get_book_diffs(previous_task_result_old, previous_task_result_new).each do |book_pv_diff|
          previous_book_pv_diffs[book_pv_diff.portfolio.id] = book_pv_diff
        end
      end

      @header[:page_name] = 'index.html'
      @header[:page_title] = "#{run_name} :: Diffs"
      @header[:header_links_disabled] = true
      @header[:nav_prefix] = 'run'

      @content[:header_text] = "Diffs - #{run_name}"

      run_config = run_result.run_config
      config_name = run_config.config_name
      application_name = run_config.application.application_name
      @content[:header_crumbs][:run_config] = {display: "#{application_name} -- #{config_name}", href: link('config', application_name, config_name, 'index.html')}
      @content[:header_crumbs][:run] = {display: run_name, href: link('run', run_name, 'index.html')}
      @content[:header_crumbs][:book_pv_diffs] = {display: 'Book Diffs'}

      @content[:run_result] = run_result
      @content[:task_result] = test_result
      @content[:book_pv_diffs] = book_pv_diffs
      @content[:previous_book_pv_diffs] = previous_book_pv_diffs
      haml view_name, format: :html5
    end

  end

end
