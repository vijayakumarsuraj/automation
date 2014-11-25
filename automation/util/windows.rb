#
# Suraj Vijayakumar
# 05 Mar 2013
#

require 'fiddle'
require 'fiddle/import'
require 'fiddle/types'

module Automation

  # Provides convenience methods for working with the Windows API libraries.
  module Windows

    # Returns a pointer to a long for use with functions that accept an 'out' parameter.
    #
    # @return [Fiddle::Pointer] the long pointer.
    def self.malloc_pdword
      Fiddle::Pointer.malloc(Fiddle::SIZEOF_LONG)
    end

    # Get the value in the specified dword pointer.
    #
    # @param [Fiddle::Pointer] pdword the dword pointer.
    # @return [Integer] the dword value.
    def self.unpack_pdword(pdword)
      value = pdword[0, Fiddle::SIZEOF_LONG].unpack('L')
      value[0]
    end

    # Provides access to the functions in the user32 DLL.
    module User32

      # DSL for ffi functions.
      extend Fiddle::Importer

      # Access to the user32 functions.
      dlload 'user32.dll'

      # Add Win32 API type aliases.
      include Fiddle::Win32Types

      # Gets the process id of the process that owns the specified window handle.
      #
      # @param [Integer] h_wnd the window handle.
      # @return [Fiddle::Pointer] the pid of the process.
      extern 'DWORD GetWindowThreadProcessId(HWND, PDWORD)'

    end

    # Provides access to the functions in the kernel32 DLL.
    module Kernel32

      # DSL for ffi functions.
      extend Fiddle::Importer

      # Access to the kernel32 functions.
      dlload 'kernel32.dll'

      # Add Win32 API type aliases.
      include Fiddle::Win32Types

      # Gets the error id of the most recent error.
      #
      # @return [Integer] the error id.
      extern 'DWORD GetLastError(void)'

    end

  end

end