#
# Suraj Vijayakumar
# 02 Nov 2014
#

require 'rexml/document'

module Automation

  module Svn

    # Represents the output of the 'info' command.
    class SvnInfo

      # Parses the specified SVN info data.
      #
      # @param [String] info_xml the raw XML string.
      # @return [SvnInfo]
      def self.parse(info_xml)
        doc = REXML::Document.new(info_xml)
        info_entry = doc.elements['info/entry']

        info = SvnInfo.new
        info.revision = info_entry.attributes['revision']
        info.url = info_entry.elements['url'].text
        info.root = info_entry.elements['repository/root'].text
        info.uid = info_entry.elements['repository/uuid'].text
        info
      end

      # @return [String]
      attr_accessor :revision
      # @return [String]
      attr_accessor :url
      # @return [String]
      attr_accessor :root
      # @return [String]
      attr_accessor :uuid

      # New empty info.
      def initialize
        @revision = ''
        @url = ''
        @root = ''
        @uuid = ''
      end

    end

  end

end
