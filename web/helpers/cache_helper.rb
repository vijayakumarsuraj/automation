#
# Suraj Vijayakumar
# 13 Feb 2013
#

module Automation

  # Provides methods for storing / retrieving cached files.
  module CacheHelpers

    # Deletes any cached data for the specified run.
    #
    # @param [String] run_name
    def cache_delete(run_name)
      cache_directory = @config_manager['run.cache.directory', parameters: {'run.name' => run_name}]
      FileUtils.rmdir(cache_directory) unless File.exist?(cache_directory)
    end

    # Puts data into the cache, unless a file with the specified name already exists.
    #
    # @param [String] directory the directory containing the cache data.
    # @param [String] file_name the name of the file.
    def cache_put(directory, file_name)
      FileUtils.mkdir_p(directory) unless File.exist?(directory)
      FileUtils.cd(directory) do
        return if File.exist?(file_name)
        # The provided block can either create the required file, or return a string that represents the required content.
        content = yield(directory)
        # If a file was created, we use that.
        # If some content was returned, we create a file with that content.
        # Otherwise, we raise an exception.
        if !File.exist?(file_name) && content.kind_of?(String)
          File.write(file_name, content)
        elsif !File.exist?(file_name)
          raise IOError.new("Cached file '#{directory}/#{file_name}' does not exist!")
        end
      end
    end

    # Gets the content of the specified file from the cache.
    # If a file with the specified name does not exist, the specified block is invoked and the result of the block
    # is cached and returned.
    #
    # @param [String] run_name the name of the run whose data is needed.
    # @param [String] file_name the name of the file.
    # @param [Hash] overrides options hash
    #   :mode - the mode in which the data should be read ('rb' for binary, 'r' for text) - default is 'r'.
    #   :encoding - the encoding of the data - default it Encoding#default_external.
    # @return [String] the data in the specified file.
    def cache_get(run_name, file_name, overrides = {}, &block)
      defaults = {mode: 'rb', encoding: Encoding.default_external}
      overrides = defaults.merge(overrides)
      # Create the cached data, if required and read it.
      cache_directory = @config_manager['run.cache.directory', parameters: {'run.name' => run_name}]
      cache_put(cache_directory, file_name, &block)
      FileUtils.cd(cache_directory) { return File.read(file_name, mode: overrides[:mode]) }
    end

    # Gets the content of the specified file from the run's cached results.
    # If the file does not exist, it is un-zipped from the result archive and used.
    #
    # @param [String] run_name the name of the run whose data is needed.
    # @param [String] file_name the name of the file.
    # @param [Hash] overrides options hash
    #   :mode - the mode in which the data should be read ('rb' for binary, 'r' for text) - default is 'r'.
    #   :encoding - the encoding of the data - default it Encoding#default_external.
    # @return [String] the data in the specified file.
    def cache_run_result_get(run_name, file_name, overrides = {})
      cache_get(run_name, file_name, overrides) do |directory|
        begin
          run_result_data = @results_archive.get_run_result(run_name)
          run_result_data.extract(file_name, directory)
        ensure
          run_result_data.close if (defined? run_result_data) && !run_result_data.nil?
        end
      end
    end

    # Gets the content of the specified file from the task's cached zip results.
    # If the task's zip file does not exist, it is un-zipped from the result archive and used.
    #
    # @param [String] run_name the name of the run whose data is needed.
    # @param [String] task_name the name of the task whose data is needed.
    # @param [String] file_name the name of the file.
    # @return [String] the data in the specified file.
    def cache_task_result_get(run_name, task_name, file_name)
      cache_directory = @config_manager['run.cache.directory', parameters: {'run.name' => run_name}]
      zip_file_name = @config_manager['task.results.zip_file_name', parameters: {'task.name' => task_name}]
      # Stream data from the zip file.
      cache_zip_get(cache_directory, zip_file_name, file_name) do
        begin
          run_result_data = @results_archive.get_run_result(run_name)
          run_result_data.extract(zip_file_name, cache_directory)
        ensure
          run_result_data.close if (defined? run_result_data) && !run_result_data.nil?
        end
      end
    end

    # Gets the content of the specified file from a zip file in the cache.
    # If a zip file with the specified name does not exist, the specified block is invoked which is responsible
    # for creating the required zip file.
    #
    # @param [String] directory the directory containing the zip file.
    # @param [String] zip_file the name of the zip file.
    # @param [String] file_name the name of the file within the zip archive.
    # @return [String] the data in the specified file.
    def cache_zip_get(directory, zip_file, file_name, &block)
      # Cache the zip file, if required.
      cache_put(directory, zip_file, &block)
      # Cache the file from the zip file, if required.
      cache_zip_directory = File.join(directory, File.basename(zip_file, '.zip'))
      cache_put(cache_zip_directory, file_name) do
        begin
          zip_data = ZipResultData.new(File.join(directory, zip_file), false)
          zip_data.extract(file_name, cache_zip_directory)
        ensure
          zip_data.close if (defined? zip_data) && !zip_data.nil?
        end
      end
      # Read data from the file.
      FileUtils.cd(cache_zip_directory) { return File.read(file_name, mode: 'rb') }
    end

  end

end
