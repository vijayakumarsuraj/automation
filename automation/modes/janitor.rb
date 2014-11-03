#
# Suraj Vijayakumar
# 08 Jan 2013
#

require 'automation/modes/support'

module Automation

  # An independent mode designed to provide support for out-of-process tasks.
  # Required since Ruby is not truly multi-threaded and calls to system libraries block the entire process.
  class Janitor < SupportMode

    private

    def run
      super

      @logger.info('Clean-up running...')
      clean_temp_folder
      clean_results_archive
      clean_database
      @logger.info('Clean-up done.')
    end

    # Cleans the results database, removing any stale data.
    def clean_database
      @logger.debug('Cleaning databases...')
      @databases.each do |key, db|
        @logger.fine("Cleaning database '#{key}'...")
        db.clean
      end
    end

    # Cleans the results archive folder, removing zombie results.
    def clean_results_archive
      @logger.debug('Cleaning results archive...')
      archive_directory = @config_manager['results.archive']
      FileUtils.cd(archive_directory) do
        files = Dir.glob('*.zip')
        files.each do |file_name|
          # Don't do anything to valid results.
          basename = File.basename(file_name, '.zip')
          run_result = @results_database.get_run_result(basename)
          next unless run_result.nil?
          # Delete zombie archive.
          @logger.fine("Deleting archive '#{file_name}'...")
          FileUtils.rm_f(file_name)
        end
      end
    end

    # Cleans the temp folder if this run has completed.
    def clean_temp_folder
      @logger.debug('Cleaning temp folder...')
      temp_directory = @config_manager['temp.directory']
      FileUtils.cd(temp_directory) do
        folders = Dir.glob('*')
        folders.each do |folder_name|
          # Don't do anything for the runs are still running.
          run_result = @results_database.get_run_result(folder_name)
          next if run_result.status != Automation::Status::Complete unless run_result.nil?
          # All other folders are deleted.
          @logger.fine("Deleting folder '#{folder_name}'...")
          FileUtils.rm_rf(folder_name)
        end
      end
    end

  end

end
