#
# Suraj Vijayakumar
# 02 Nov 2014
#

require 'rexml/document'

module Automation

  module Svn

    # Represents a path from the SVN log.
    class SvnPath

      # @return [String]
      attr_accessor :kind
      # @return [String]
      attr_accessor :action
      # @return [String]
      attr_accessor :path

      # New empty path.
      def initialize
        @kind = ''
        @action = ''
        @path = ''
      end

    end

    # Represents the output of the 'log' command.
    class SvnLog

      # Parses SVN log xml data.
      #
      # @param [String] log_xml the raw XML string.
      # @return [Array<SvnLog>] an array containing details of each log entry.
      def self.parse(log_xml)
        log_entries = []
        doc = REXML::Document.new(log_xml)
        doc.elements.each('log/logentry') do |log_entry_xml|
          log_entries << (log_entry = SvnLog.new)
          log_entry.revision = log_entry_xml.attributes['revision']
          log_entry.author = log_entry_xml.elements['author'].text
          log_entry.date = log_entry_xml.elements['date'].text
          log_entry.message = log_entry_xml.elements['msg'].text
          log_entry_xml.elements.each('paths/path') do |affected_path|
            log_entry.paths << (path = SvnPath.new)
            path.kind = affected_path.attributes['kind']
            path.action = affected_path.attributes['action']
            path.path = affected_path.text
          end
        end

        log_entries
      end

      private

      # @return [String]
      attr_accessor :revision
      # @return [String]
      attr_accessor :author
      # @return [String]
      attr_accessor :date
      # @return [String]
      attr_accessor :message
      # @return [Array<SvnPath>]
      attr_accessor :paths

      # New empty log.
      def initialize
        @revision = ''
        @author = ''
        @date = ''
        @message = ''
        @paths = []
      end

    end

  end

end
