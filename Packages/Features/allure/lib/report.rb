require 'uuid'
require 'open3'
require 'rexml/document'
require 'rexml/formatters/pretty'

module Automation::Allure

  module Report

    # Merge all the allure reports in the specified output directory.
    # The result is one xml file per test suite.
    #
    # @param [String] output_directory
    def self.merge(output_directory)
      logger = Logging::Logger[self]
      FileUtils.cd(output_directory) do
        docs = {}
        Dir.glob('*-testsuite.xml') do |suite_file|
          File.open(suite_file) do |f|
            doc = REXML::Document.new(f)
            start_time = doc.root.attributes['start'].to_i
            stop_time = doc.root.attributes['stop'].to_i
            name = doc.root.elements['name'].text
            logger.fine("Processing suite '#{name}' (#{suite_file})...")
            # If a suite with this name has already been seen, need to merge this document with the existing one.
            # Otherwise, just save this entire document.
            if docs.has_key?(name)
              existing_doc = docs[name].root
              # First the start and stop times.
              existing_start_time = existing_doc.attributes['start'].to_i
              existing_stop_time = existing_doc.attributes['stop'].to_i
              existing_doc.attributes['start'] = start_time if existing_start_time > start_time
              existing_doc.attributes['stop'] = stop_time if existing_stop_time < stop_time
              # Then add all the test cases (usually there will only be one).
              doc.root.elements.each('test-cases/test-case') do |test_case|
                existing_doc.elements['test-cases'].add_element(test_case)
              end
            else
              docs[name] = doc
            end
          end
          # Done with that file, so rename it.
          FileUtils.mv(suite_file, "#{suite_file}.original")
        end
        # Generate the merged xml files - one per test suite.
        formatter = REXML::Formatters::Pretty.new
        formatter.compact = true
        docs.each_pair do |name, doc|
          logger.fine("Generating merged output for suite '#{name}'...")
          File.open("#{UUID.new.generate}-testsuite.xml", 'w') { |f| formatter.write(doc, f) }
        end
      end
    end

    # Generate an allure report off of the xml files in the specified directory.
    #
    # @param [String] output_directory
    # @param [String, Process::Status] executable
    def self.generate(output_directory, executable)
      allure_args = ['generate', '-o', output_directory, output_directory]
      Logging::Logger[self].fine(allure_args.inspect)
      Open3.capture2e(executable, *allure_args)
    end

  end

end
