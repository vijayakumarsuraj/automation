#
# Suraj Vijayakumar
# 14 Feb 2013
#

module Automation

  module DateTimeHelpers

    FORMATS = {date_with_day: '%a, %d-%b-%Y', date_time: '%d-%b-%Y %I:%M %P',
               date_time_with_day: '%a, %d-%b-%Y %I:%M %P', date_time_long: '%d-%b-%Y %I:%M:%S %P',
               time: '%I:%M %P', time_24h: '%H:%M:%S'}

    # Formats the duration (i.e. difference between the specified date time objects)
    #
    # @param [DateTime] start_date the start date time.
    # @param [DateTime] end_date the end date time.
    def date_time_duration(start_date, end_date)
      Converter.seconds_to_duration(end_date - start_date)
    end

    # Formats the specified date time object.
    #
    # @param [DateTime] date_time the date time object to format.
    # @param [String] format an optional format string (default is DateTimeFormat::DATE_TIME).
    def date_time_format(date_time, format = :date_time)
      format = FORMATS[format]
      date_time.strftime(format)
    end

  end

end