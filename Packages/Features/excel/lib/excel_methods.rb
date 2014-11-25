#
# Suraj Vijayakumar
# 05 Mar 2013
#

require 'win32ole'

module Automation::Excel

  # General excel error.
  class Error < Automation::Error
  end

  # Provides methods to manually calculate the cells / sheets in an Excel workbook.
  module CalculationMethods

    # Reference style R1C1
    R1C1 = -4150

    private

    # Calls the specified Excel macro / function.
    #
    # @param [String] method the macro or function name.
    # @param [Array] args the arguments to pass to the function.
    def excel_call(method, *args)
      @excel.Application.Run(method.to_s, *args)
    end

    # Get the hash that keeps track of which cells have been calculated.
    #
    # @return [Hash]
    def excel_calculated_cells
      @calculated_cells = {} unless defined? @calculated_cells
      @calculated_cells
    end

    # Calculates the specified cell. If the cell has already been calculated (i.e. if it is part of an array formula
    # that has already been calculated), it is not calculated.
    # If a cell is calculated, it is added to the @calculated_cells list.
    def excel_calculate_cell(cell)
      cell_address = cell.Address(false, false, R1C1)

      # Already calculated? Return immediately.
      return if excel_calculated_cells.has_key?(cell_address)

      # Array formula? Calculate the first cell only.
      if cell.HasArray
        array_cells = cell.CurrentArray
        first_cell = array_cells.Cells(1, 1)
        cell_address = first_cell.Address(false, false, R1C1)
        # Already calculated the first cell? Return immediately
        return if excel_calculated_cells.has_key?(cell_address)
        # Array formulae cannot be calculated in part. The entire array must be calculated.
        cell = array_cells
      end
      # Cell needs to be calculated. So do that now.
      cell.Calculate()
      # Save the address so that it is not re-calculated (for the current sheet).
      excel_calculated_cells[cell_address] = true
    end

    # Calculates the specified sheet in a determinate row-major order.
    # Returns an array with the output.
    #
    # @return [Array<Array<String>>] the 2D array with the results of the calculation.
    def excel_calculate_sheet(sheet)
      excel_calculated_cells.clear

      # Iterate over the used range calculating each cell.
      # The result of each cell is then saved.
      data = []
      begin
        sheet.UsedRange.Rows.each do |row|
          data << row_data = []
          row.Cells.each do |cell|
            # Calculate the cell if required.
            excel_calculate_cell(cell) if cell.HasFormula
            # Get the un-formatted value of this field.
            value = cell.Value2
            row_data << value
          end
        end
      rescue
        @logger.error(format_exception)
        data << ["#{$!.message} (#{$!.class.name})"]
        data << [$!.backtrace.join("\n")]
      end
      # Return the 2d array with all the data.
      data
    end

  end

  # Provides methods to work with the Excel automation object.
  module Methods

    # Provides access to manual Excel calculation methods.
    include Automation::Excel::CalculationMethods

    private

    # Executes the specified block after changing the working directory of the Excel process.
    # Once the block completes, the working directory is reset.
    #
    # @param [String] new_wd the new working directory.
    def excel_change_directory(new_wd)
      new_wd = File.expand_path(new_wd)
      raise ExcelError.new("Cannot change working directory - '#{new_wd}' does not exist") unless File.exist?(new_wd)

      begin
        orig_wd_w = Converter.to_windows_path(Dir.pwd)
        new_wd_w = Converter.to_windows_path(new_wd)
        # In some machines, ChDir will not change the directory immediately.
        # So to make sure, first change the drive and then change the directory if the directory is absolute.
        excel_call('ChangeWorkingDrive', new_wd_w[0..1]) if new_wd_w[1] == ?:
        excel_call('ChangeWorkingDirectory', new_wd_w)
        current_dir = excel_call('ShowWorkingDirectory')
        @logger.trace('Changed Excel.exe working directory: ' + current_dir)
        # Execute the provided block.
        yield
      ensure
        # All done, reset working directory.
        excel_call('ChangeWorkingDrive', orig_wd_w[0..1]) if orig_wd_w[1] == ?:
        excel_call('ChangeWorkingDirectory', orig_wd_w)
        current_dir = excel_call('ShowWorkingDirectory')
        @logger.trace('Reset Excel.exe working directory: ' + current_dir)
      end
    end

    # Creates the Excel automation object.
    def excel_create
      raise ExcelError.new('Cannot create excel! An instance is already open') unless @excel.nil?

      @excel = WIN32OLE.new('Excel.Application', 'localhost')
      @excel.DisplayAlerts = false
      update_pid(excel_pid)
    end

    # Destroys the Excel automation object.
    def excel_destroy
      if defined? @excel && !@excel.nil?
        @workbook.Close(false) if (defined? @workbook) && !@workbook.nil?
        @excel.Quit
        @excel = nil
        # Kill the Excel process, if it is still alive.
        Process.kill('KILL', pid)
      end
    rescue
      @logger.warn("Could not destroy Excel object - #{format_exception($!)}")
    end

    # Registers the required Excel DLLs.
    #
    # @param [Array] libraries the names of the libraries to register.
    def excel_dlls_register(libraries)
      failed_registrations = []
      # Register the DLLs.
      libraries.each do |library|
        dll_name = @config_manager["library.#{library}.excel_dll"].strip
        @logger.fine("Registering '#{dll_name}'...")
        unless @excel.RegisterXLL(dll_name)
          @logger.warn("Registration failed for '#{dll_name}'.")
          failed_registrations << dll_name if @config_manager["library.#{library}.required", default: false]
        end
      end
      # Raise an exception if any required DLLs did not get registered.
      raise ExcelError.new("Registration failed for: #{failed_registrations.join(', ')}") if failed_registrations.length > 0
    end

    # The PID of the Excel.exe automation process.
    #
    # @return [Integer] the Excel.exe process' PID. Returns 0 if the pid could not be determined.
    def excel_pid
      pid = Windows.malloc_pdword
      thread_id = Windows::User32.GetWindowThreadProcessId(@excel.hWnd, pid)
      if thread_id == 0
        error_id = Windows::Kernel32.GetLastError()
        @logger.warn("Could not get Excel process id - error code: #{error_id}")
        0
      else
        Windows.unpack_pdword(pid)
      end
    end

    # Executes the specified block after loading the TestFramework.xla add-in.
    # Once the block completes, the add-in is unloaded.
    def excel_test_framework_addin
      # Get the path to the add-in.
      addin_file = 'TestFramework.xla'
      features_directory = @config_manager['features_directory']
      macro_dir = File.join(features_directory, 'excel/macros')
      addin_source_path = File.join(macro_dir, addin_file)
      addin_source_time = File.mtime(addin_source_path)
      # The excel add-in will be loaded from a trusted location.
      excel_trusted_dir = File.join(ENV['APPDATA'], 'Microsoft/Excel/XLSTART')
      addin_destination_path = File.join(excel_trusted_dir, addin_file)
      # Compare the dates on the source and destination, replacing the destination if the source is newer.
      if File.exist?(addin_destination_path)
        addin_destination_time = File.mtime(addin_destination_path)
        FileUtils.cp(addin_source_path, addin_destination_path) if addin_source_time > addin_destination_time
      else
        FileUtils.mkdir_p(excel_trusted_dir)
        FileUtils.cp(addin_source_path, addin_destination_path)
      end
      # Open the excel add-in from the trusted location.
      temp_book = @excel.Workbooks.Open(addin_destination_path)
      # Execute the provided block.
      yield
    ensure
      # All done. Close the temporary book we used to load the add-in.
      if (defined? temp_book) && !temp_book.nil?
        temp_book.Saved = true
        temp_book.Close(false)
      end
    end

  end

end
