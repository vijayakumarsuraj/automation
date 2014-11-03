#
# Suraj Vijayakumar
# 08 Mar 2013
#

module Automation

  module DateTimeFormat

    TIME = '%H:%M:%S'
    TIME_WITH_MILLISECOND = '%H:%M:%S.%L'

    TIMEZONE = '%z'

    SHORT_DATE = '%d-%m-%Y'
    LONG_DATE = '%d-%b-%Y'
    LONG_DATE_WITH_DAY = '%A, %d-%b-%Y'

    DATE_TIME = "#{LONG_DATE} #{TIME}"
    DATE_TIME_WITH_TIMEZONE = "#{DATE_TIME} #{TIMEZONE}"

    DATE_TIME_WITH_MILLISECOND = "#{LONG_DATE} #{TIME_WITH_MILLISECOND}"
    DATE_TIME_WITH_TIMEZONE_MILLISECOND = "#{DATE_TIME_WITH_MILLISECOND} #{TIMEZONE}"

    TIMESTAMP = "%Y-%m-%d #{TIME_WITH_MILLISECOND}"
    TIMESTAMP_WITH_TIMEZONE = "#{TIMESTAMP} #{TIMEZONE}"

    SORTABLE_TIMESTAMP = '%Y%m%d_%H%M%S_%L'

    EXCEL_DATE = '%d/%b/%Y'

  end

end