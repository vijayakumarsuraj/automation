#
# Suraj Vijayakumar
# 18 Mar 2013
#

module Automation

  # The WebApp application.
  # This file contains the routes for the pages related to runs.
  class WebApp < Sinatra::Application

    # Run result page.
    get '/run/:run_name/:page_name.html' do |run_name, page_name|
      raise Sinatra::NotFound unless view_exist?("run/#{page_name}")

      run_result = @results_database.get_run_result(run_name)
      raise WebError.new("Sorry, but we could not find any results for '#{run_name}'!") if run_result.nil?

      @header[:page_name] = "#{page_name}.html"
      @header[:page_title] = "#{run_name} :: Automation Results"
      @header[:nav_prefix] = 'run'

      @content[:header_text] = "Automation Results - #{run_name}"

      run_config = run_result.run_config
      config_name = run_config.config_name
      application_name = run_config.application.application_name
      @content[:header_crumbs][:run_config] = {display: "#{application_name} -- #{config_name}", href: link('config', application_name, config_name, 'index.html')}
      @content[:header_crumbs][:run] = {display: run_name}

      @content[:previous_run_result] = @test_database.get_analysed_against_run_result(run_result)
      @content[:run_result] = run_result
      haml :"run/#{page_name}", format: :html5
    end

    # Static run result content.
    get '/run/:run_name/static/:page_name' do |run_name, page_name|
      content = cache_run_result_get(run_name, page_name)
      page_ext = File.extname(page_name).downcase
      content_type STATIC_MIME_TYPES[page_ext] if STATIC_MIME_TYPES.has_key?(page_ext)
      # If a special encoding value has been provided, use that.
      encoding = params['encoding']
      if encoding
        content.force_encoding(encoding)
        content.encode!('UTF-8', invalid: :replace, undef: :replace)
      end
      # Render the content.
      content
    end

    # Static task result content.
    get '/run/:run_name/task/:task_name/static/:page_name' do |run_name, task_name, page_name|
      content = cache_task_result_get(run_name, task_name, page_name)
      page_ext = File.extname(page_name).downcase
      content_type STATIC_MIME_TYPES[page_ext] if STATIC_MIME_TYPES.has_key?(page_ext)
      # If a special encoding value has been provided, use that.
      encoding = params['encoding']
      if encoding
        content.force_encoding(encoding)
        content.encode!('UTF-8', invalid: :replace, undef: :replace)
      end
      # Render the content.
      content
    end

    # Test benchmark vs output diff.
    get '/run/:run_name/test/:test_name/diff.html' do |run_name, test_name|
      diff_file_name = "#{test_name}.diff"
      cache_get(run_name, diff_file_name) do
        benchmark_file_name = "#{test_name}.bench"
        benchmark_content = cache_task_result_get(run_name, test_name, benchmark_file_name)
        output_file_name = "#{test_name}.out"
        output_content = cache_task_result_get(run_name, test_name, output_file_name)
        # Generate the diff file.
        params = {title_left: "Expected (#{benchmark_file_name})", title_right: "Actual (#{output_file_name})"}
        generate_content_diff(benchmark_content, output_content, params)
      end
    end

    # Test output vs prev. output diff.
    get '/run/:run_name/test/:test_name/ddiff.html' do |run_name, test_name|
      d_diff_file_name = "#{test_name}.ddiff"
      cache_get(run_name, d_diff_file_name) do
        output_file_name = "#{test_name}.out"

        # This run result.
        this_run_result = @results_database.get_run_result(run_name)
        raise WebError.new("Sorry, but we couldn't find the required run results (#{run_name})!") if this_run_result.nil?

        # Previous run result.
        previous_run_result = @test_database.get_analysed_against_run_result(this_run_result)
        raise WebError.new("Sorry, but we couldn't find any previous run results (#{run_name})!") if previous_run_result.nil?
        previous_run_name = previous_run_result.run_name

        # Get the required output files.
        benchmark_content = cache_task_result_get(previous_run_name, test_name, output_file_name)
        output_content = cache_task_result_get(run_name, test_name, output_file_name)
        # Generate the diff file.
        params = {title_left: "Previous (#{previous_run_name})", title_right: "This (#{run_name})"}
        generate_content_diff(benchmark_content, output_content, params)
      end
    end

    post '/run/delete' do
      run_names = params['values'].split(',')
      action_items(run_names) do |run_name|
        run_result = @results_database.get_run_result(run_name)
        raise 'Cannot delete; does not exist' if run_result.nil?
        raise 'Cannot delete; still running' if run_result.status == Automation::Status::Running
        # Delete the DB entry and also remove any archived / cached results.
        db_destroy_run_result(run_result)
        run_result_delete_archive(run_name)
        cache_delete(run_name)
      end
    end

    post '/run/invalidate' do
      run_names = params['values'].split(',')
      action_items(run_names) do |run_name|
        run_result = @results_database.get_run_result(run_name)
        raise 'Cannot invalidate; does not exist' if run_result.nil?
        raise 'Cannot invalidate; already invalidated' if run_result.result == Automation::Result::Ignored
        raise 'Cannot invalidate; still running' if run_result.status == Automation::Status::Running
        # Invalidate!
        run_result.invalidate
      end
    end

    post '/run/:run_name/stop' do |run_name|
      test_names = []
      test_results = []
      params['values'].split(',').each do |id|
        test_result = @test_database.find_test_result(id)
        test_names << (test_result.nil? ? id : test_result.test.test_name)
        test_results << test_result
      end
      action_items(test_names, test_results) do |test_name, test_result|
        raise 'Cannot stop; does not exist' if test_result.nil?
        raise 'Cannot stop; not running' if test_result.status != Automation::Status::Running

        target = test_result.properties['target']
        raise 'Cannot stop; target host unknown' if target.nil?
        host, pid = target.split(':')
        Integer(pid) rescue (raise "Cannot stop; target '#{target}' not valid")

        output, status = popen_capture('taskkill', '/S', host, '/PID', pid, '/T', '/F')
        return_value = status.exitstatus
        if return_value != 0
          @logger.warn(output)
          raise "Cannot stop; command 'taskkill' failed"
        end

        # Now, we need to populate the end_date_time field manually, and mark the test as timed out.
        test_result.end_date_time = DateTime.now
        test_result.result = Automation::Result::Exception
        test_result.save
      end
    end

    # Perform an action on the specified list of items.
    # Updates the :warn and :pass flash messages automatically.
    #
    # @param [Array<String>] items_array any number of arrays. the arrays are 'zipped' together and each 'row' is yielded.
    def action_items(*items_array)
      success_items = []
      warn_items = []
      warn_messages = []
      # Combine the item arrays into a single array.
      items_array = items_array[0].zip(*items_array[1..-1])
      items_array.each do |items|
        begin
          yield *items
          success_items << items[0]
        rescue
          warn_messages << $!.message
          @logger.warn(format_exception($!))
          warn_items << items[0]
        end
      end

      # Add messages for warnings.
      flash_warn = []
      warn_items.each_with_index { |item, i| flash_warn << "<strong>#{item}</strong> - #{warn_messages[i]}" }
      flash[:warn] = flash_warn.join('<br/>') if flash_warn.length > 0
      # Add messages for successes.
      info_count = success_items.length
      if info_count == 1
        flash[:pass] = "'#{success_items[0]}' updated"
      elsif info_count > 1
        flash[:pass] = "#{info_count} items updated: #{success_items.join(', ')}"
      end
    end

  end

end