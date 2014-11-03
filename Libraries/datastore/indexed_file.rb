#
# Suraj Vijayakumar
# 04 Aug 2013
#

require 'logging'

module DataStore

  # Provides an efficient way for accessing flat file data.
  # The data in the flat file is indexed (and accessible) using line numbers.
  class IndexedFile

    # New indexed file.
    #
    # @param [String] path the full path of the file to index.
    def initialize(path)
      @path = path

      @index_path = "#{path}.index"
      @logger = Logging::Logger["IndexedFile(#{File.basename(path)})"]

      @data = File.open(@path, 'r')
      @data_timestamp = File.mtime(@path).to_i

      load_index
    end

    # Closes the file (and the index file also).
    def close
      @data.close
      @index.close
    end

    # Check if the index is valid.
    def index_valid?
      timestamp = File.open(@index_path, 'rb') { |f| read_int(0, f) }
      timestamp == @data_timestamp
    rescue
      false
    end

    # Reads a line of data from the underlying data file.
    #
    # @param [Integer] line_no the line to read (0 based).
    # @return [String] the line of data (without a trailing new-line character).
    def readline(line_no)
      index_offset = 4 + (line_no * 4)
      data_offset = read_int(index_offset)

      @data.seek(data_offset)
      @data.readline.chomp
    end

    private

    # Constructs the index for the data file.
    def construct_index
      @logger.fine('Constructing index...')
      File.open(@index_path, 'wb') do |f|
        write_int(@data_timestamp, f) # The timestamp value - used to determine if an index is valid.
        write_int(0, f) # The first row - always at offset 0.
        @data.each_line { write_int(@data.pos, f) } # The rest of the rows.
      end
    end

    # Loads the index file, updating it if required.
    def load_index
      construct_index unless index_valid?
      open_index_file
    end

    # Opens the index file.
    def open_index_file
      @index = File.open(@index_path, 'rb')
    end

    # Reads a 4-byte integer from the index file.
    #
    # @param [Integer] offset the offset at which to read the integer.
    # @param [IO] stream the stream to read from, defaults to the index file.
    # @return [Integer] the integer value.
    def read_int(offset, stream = @index)
      stream.seek(offset)
      stream.read(4).unpack('L')[0]
    end

    # Writes a 4-byte integer to the index file.
    #
    # @param [Integer] value the value to write.
    # @param [IO] stream the stream to write to, defaults to the index file.
    def write_int(value, stream = @index)
      stream.write([value].pack('L'))
    end

  end

end
