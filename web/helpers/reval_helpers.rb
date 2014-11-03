#
# Suraj Vijayakumar
# 02 Dec 2013
#

module Automation

  # Provides methods for accessing and working with the Reval database.
  module RevalHelpers

    # Performs initializations that are specific to the reval pages.
    def reval_before
      return unless @path_info.start_with?('/reval/')

      @header[:styles] << 'reval.css'
      @reval_database = @databases['reval']
    end

    # Returns the diff percent for the specified diff.
    #
    # @param [Automation::Reval::RevalDatabase::DealRisk] diff
    # @return [Float]
    def reval_diff_percent(diff)
      base_value = diff.base_value
      diff_value = diff.diff
      diff_value.nil? ? nil : (diff_value / base_value).abs
    end

    # Returns the style class based on the diff value.
    #
    # @param [Float] diff_percent
    # @return [String]
    def reval_diff_style(diff_percent)
      failure_threshold = @config_manager['reval.web.failure_threshold']
      if diff_percent.nil?
        'exception'
      elsif diff_percent > failure_threshold
        'fail'
      else
        ''
      end
    end

    # Formats the specified number.
    #
    # @param [Float, Integer] number
    # @return [String]
    def reval_format_number(number)
      return '-' if number.nil?
      Automation::Converter.to_number_with_delimiter('%.2f' % number, ',')
    end

  end

end