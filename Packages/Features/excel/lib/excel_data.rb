#
# Suraj Vijayakumar
# 25 Mar 2013
#

require 'automation/core/component'

require 'excel/excel_methods'

module Automation::Excel

  class Data < Component

    # Provides support for working with Excel.
    include Automation::Excel::Methods

    # Flag to indicate if a blank cell should be treated as a nil and stripped from the final output. Default is true.
    attr_accessor :strip_blanks
    # The process id of the Excel process used to read data.
    attr_reader :pid

    # Creates a wrapper for the result data in the specified directory.
    #
    # @param [Boolean] strip_blanks If true empty string values are not saved.
    def initialize(strip_blanks = true)
      super()

      @component_name = @component_name.snakecase
      @component_type = Automation::Component::CoreType

      @strip_blanks = strip_blanks
      @data = {}
    end

    # Override for debugging.
    def inspect
      str = ''
      @data.each_value do |value|
        str << "#{value}\n"
        str << value.inspect
      end
      # Return the string.
      str
    end

    # Allow access using the [] operator.
    def [](header)
      get_header(header)
    end

    # Adds a header to the data.
    # The name is converted to a +Symbol+ before it is added.
    # Returns the header object.
    def add_header(name)
      add_header_object(Header.new(name, @logger))
    end

    # Adds a header object to the data.
    # Returns the header object.
    def add_header_object(header)
      key = header.name

      @logger.warn("New header '#{header}' overwrites an existing header.") if has_header?(key)
      @data[key] = header
      # Return
      header
    end

    # Get the data identified by the specified header and variable.
    def get(header, variable)
      get_header(header).get_variable(variable).data
    end

    # Get the header identified by the specified name.
    def get_header(header)
      raise DataError.new("Header '#{header}' does not exist.") unless has_header?(header)

      # All good return the data.
      @data[header]
    end

    # Check if a header identified by the specified name exists. Returns true if it exists, false otherwise.
    def has_header?(header)
      @data.has_key?(header)
    end

    # Loads the data from the specified file.
    def load_from_file(file_path)
      all_data = read_all_data(file_path)
      process(all_data)
    end

    private

    # Converts a date object into a time object.
    # This is required since ExcelData loads dates as Ruby Date objects and WIN32OLE only converts Time
    # objects correctly.
    def date_to_time(date)
      time_str = date.strftime(Utils::DateTimeFormat::DATE_SHORT)
      DateTime.strptime(time_str, Utils::DateTimeFormat::DATE_SHORT)
    end

    # Process the specified 2D all data array.
    def process(all_data)
      current_header = nil

      all_data.each_with_index do |row, row_number|
        # Check the value in the first column. Go to the next row if it is empty (i.e. nil).
        value_at_0 = row[0]
        next if value_at_0.nil?

        # Next header found. The last found header is now the current header, and the current header is now a new header.
        # This header starts from here. Keep going to find the end.
        last_found_header = current_header
        current_header = Header.new(value_at_0, @logger)
        current_header.start = row_number
        # Add this new header to the data.
        add_header_object(current_header)
        unless last_found_header.nil?
          # The next header has started now. So the end row of the last found header is the current row minus one.
          # We know the size so process it.
          last_found_header.end = (row_number - 1)
          process_header(all_data, last_found_header)
        end
      end

      # The last header. End it at the end of the used range.
      # If there were 0 headers then do nothing.
      unless current_header.nil?
        current_header.end = all_data.length - 1
        process_header(all_data, current_header)
      end
    end

    # Processes the specified header.
    def process_header(all_data, header)
      @logger.finer("Processing header '#{header}'...")

      # The start row of the header.
      # The variables data are present on the next row.
      start_row = header.start
      variables = all_data[start_row + 1]

      current_variable = nil
      # This loop will iterate through the row, identifying the column at which
      # a variable started, and the column at which it ended. It also calls the
      # load_data method each time an end is identified.
      variables.each_with_index do |item, column_number|
        # Check the value of the item. Go to the next item if it is empty (i.e. nil).
        next if item.nil?

        # Next variable found. The current variable becomes the last found variable.
        # This variable starts here. Keep going to find the end.
        last_found_variable = current_variable
        current_variable = Automation::ExcelData::Variable.new(item)
        current_variable.start = column_number
        # Add this new variable to the header.
        header.add_variable_object(current_variable)
        unless last_found_variable.nil?
          # The next variable has started now. So load data from the previous variable.
          # We know the size of the header and variable. Process all data within them.
          last_found_variable.end = (column_number - 1)
          process_variable(all_data, header, last_found_variable)
        end
      end

      # The last variable. End it at the end of the used range.
      # If there were 0 variables then do nothing.
      unless current_variable.nil?
        # The last variable.
        current_variable.end = -1
        process_variable(all_data, header, current_variable)
      end
    end

    # Process the specified variable.
    def process_variable(all_data, header, variable)
      # The full span of this data. This includes any trailing blank cells.
      # Those cells will be trimmed and will not form part of the final array.
      start_row = header.start + 2
      end_row = header.end
      start_column = variable.start
      end_column = variable.end
      # The data array. This will be a 2-d array. Even for single values.
      data_2d = Array.new
      # The row numbers.
      row_numbers = (start_row..end_row)
      # This loop will through the rows. Iterating through the columns for each of those rows.
      # An array is created for each row. Data is inserted into the array. Nils are not inserted.
      # If the @strip_blank_cells is true then blank cells are also skipped.
      # Finally if a row had no data (length is 0), it is also skipped.
      row_numbers.each_with_index do |row_number, i|
        row_data = Array.new
        # If the end column is -1 then this is the last variable for this header. And it extends till the end of the row.
        actual_end_column = end_column
        actual_end_column = all_data[row_number].length - 1 if end_column == -1
        column_numbers = (start_column..actual_end_column)
        # Get the data in each cell.
        column_numbers.each_with_index do |column_number, j|
          # Cell value.
          item = all_data[row_number][column_number]
          # Insert if there was data.
          save_data(row_data, j, item)
        end
        data_2d[i] = row_data if row_data.length > 0
      end
      # Examine data.
      # If it has only 1 row convert into a 1-d array.
      # If that row has only 1 column, convert into a single value.
      if data_2d.length == 0
        # No data. Insert a nil.
        data_2d = nil
      elsif data_2d.length == 1 && data_2d[0].length == 1
        data_2d = data_2d[0][0] # 1x1 = single value.
      elsif data_2d.length == 1 && data_2d[0].length > 1
        data_2d = data_2d[0] # 1xN = N array.
      end
      # Save the data.
      variable.data = data_2d
    end

    # Reads all the data from the workbook. The workbook is closed after the data is read.
    # The data is loaded and returned as a 2D array.
    def read_all_data(file_path)
      # Convert from relative to absolute. If it is already absolute, does nothing and returns string as is.
      file_path = File.expand_path(file_path)
      all_data = []
      begin
        excel_create

        @workbook = @excel.Workbooks.Open(file_path)
        worksheet = @workbook.Worksheets('Data')
        # Check if the worksheet was found.
        raise DataError.new("Sheet 'Data' not found!") if worksheet.nil?

        # Read all the data.
        worksheet.UsedRange.Rows.each do |row|
          row_data = []
          row.Cells.each { |cell| row_data << cell.Value2 }
          all_data << row_data
        end
      ensure
        excel_destroy
      end
      # Return all data array.
      all_data
    end

    # Inserts the specified data into the specified array at the specified index.
    # If the data is nil, then it is not inserted.
    # If the data is a formula, then the last calculated value is used.
    # If the data is an empty string and strip_blanks is true, then it is not inserted.
    # If the data is an instance of Time it is converted to a Date.
    def save_data(array, index, item)
      return if item.nil?

      # Strings will stripped and added.
      # Dates will converted to Time objects and added.
      if item.instance_of?(String)
        item = item.strip
        # If the strip blanks flag is true, and this item is blank, return.
        return if @strip_blanks && item.length == 0
      elsif item.instance_of?(Date)
        # Convert dates to times. WIN32OLE works smoothly with time objects.
        item = date_to_time(item)
      end

      array[index] = item
    end

    # Saves the PID of the Excel process that is used to read data.
    def update_pid(pid)
      @pid = pid
    end

  end

  # A simple wrapper for a name and a value.
  # The value can be a single value, an array or an array of arrays.
  class Data::Variable

    # The name of this variable. This name must be unique per header. Non-unique values will overwrite older values.
    attr_reader :name
    # The value.
    attr_accessor :data
    # The index at which the variable started.
    attr_accessor :start
    # The index at which the variable ended.
    attr_accessor :end

    # New variable.
    def initialize(name)
      if name.kind_of?(Symbol)
        @name = name
      else
        @name = name.to_s.to_sym
      end

      @data = nil
      @start = nil
      @end = nil
    end

    # Debug method. Prints the contents of the variable to the standard output.
    def inspect
      "\t\t#{@data.inspect}\n"
    end

    # Override to return the name of the variable.
    def to_s
      @name.to_s
    end

  end

  # Header is wrapper for a name and a named list of variables.
  class Data::Header

    # The name of the header.
    attr_reader :name
    # The index at which the header started.
    attr_accessor :start
    # The index at which the header ended.
    attr_accessor :end

    # New empty header.
    def initialize(name, logger)
      if name.kind_of?(Symbol)
        @name = name
      else
        @name = name.to_s.to_sym
      end

      @logger = logger
      @variables = {}
      @start = nil
      @end = nil
    end

    # Debug method. Prints the contents of the header to the standard output.
    def inspect
      str = ''
      @variables.each_value do |value|
        str << "\t#{value}\n"
        str << value.inspect
      end
      # Return the string.
      str
    end

    # Return the contents of this header as an array.
    def to_a
      values = []
      @variables.each_value { |value| values << value.data }
      values
    end

    # Override to return the name of the header.
    def to_s
      @name.to_s
    end

    # Allow access using the [] operator.
    def [](variable)
      get_variable(variable)
    end

    # Adds a variable object to this header.
    # The variable's name is converted to a Symbol before it is added.
    # Returns the variable object.
    def add_variable(name)
      add_variable_object(Automation::ExcelData::Variable.new(name))
    end

    # Adds a variable object to this header. Existing variables are overwritten.
    # Returns the variable object.
    def add_variable_object(variable)
      key = variable.name

      @logger.warn("Variable '#{self}.#{variable}' overwrites an existing variable.") if has_variable?(key)
      @variables[key] = variable
      # Return
      variable
    end

    # Get the data identified by the specified variable name.
    def get(variable)
      get_variable(variable).data
    end

    # Get the variable identified by the specified name.
    def get_variable(variable)
      raise DataError.new("Variable '#{self}.#{variable}' does not exist!") unless has_variable?(variable)

      @variables[variable]
    end

    # Check if a variable identified by the specified name exists. Returns true if it exists, false otherwise.
    def has_variable?(variable)
      @variables.has_key?(variable)
    end

  end

end
