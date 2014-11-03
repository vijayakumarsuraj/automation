#
# Suraj Vijayakumar
# 06 May 2014
#

require 'set'
require 'zlib'
require 'fileutils'

require 'datastore/error'
require 'datastore/indexed_file'

module DataStore

  # Provides an efficient way for storing text data.
  # The data in the flat file is indexed (and accessible) using keys defined for each line.
  class KeyIndexedFile < IndexedFile

    # The path to the keyed index folder.
    attr_reader :index_folder

    # New indexed file.
    #
    # @param [String] path the keyed index file.
    def initialize(path)

      super

      @index_folder = "#{path}.keys"
      @logger = Logging::Logger["KeyIndexedFile(#{File.basename(path)})"]
    end

    # Builds the index for the underlying data file.
    # This method must be called each time the file is updated.
    #
    # @param [Proc] key_builder the callback for generating keys for each line in the data file.
    def build_index(&key_builder)
      hashes = Hash.new { |h, k| h[k] = [] }
      keys = {}
      pos = 0

      @logger.fine('Generating hash...')
      @data.seek(0)
      @data.each_line do |line|
        key = key_builder.call(line)
        raise IndexError.new("Key '#{key}' already mapped") if keys.has_key?(key)

        keys[key] = true
        hash = get_hash(key)
        hashes[hash] << [key, pos]
        pos = @data.pos
      end

      # Generate the index files now.
      @logger.fine('Constructing index...')
      FileUtils.rm_r(@index_folder) if File.exist?(@index_folder)
      FileUtils.mkdir(@index_folder)
      hashes.each_pair do |hash, data|
        data = data.sort { |d1, d2| d1[0] <=> d2[0] }
        path = File.join(@index_folder, "#{hash}.index")
        File.open(path, 'wb') do |f|
          write_int(@data_timestamp, f) # The timestamp for this index file.
          data.each { |key, offset| f.write([key, offset].pack('Z*L')) } # The keys mapped to this index file.
        end
      end

      nil
    end

    # Closes the file.
    def close
      @data.close
    end

    # Reads a line of data from the underlying data file.
    #
    # @param [String] key the key that identifies the required line.
    # @return [String] the line of data (without a trailing new-line character).
    def readline(key)
      data_offset = lookup_key(key)
      return KeyError.new("Key '#{key}' not found") if data_offset.nil?

      @data.seek(data_offset)
      @data.readline.chomp
    end

    private

    # Constructs the index for the data file.
    # Does nothing, since the indices for keyed files are build explicitly using the #build_index method.
    def construct_index
    end

    # Check if the index of a particular key is valid.
    # Always returns false, since the indices for keyed files are checked only when a key is requested.
    def index_valid?
      false
    end

    # Opens the index file.
    # Always returns false, since the indices for keyed files are opened only when a key is requested.
    def open_index_file
    end

    # Get the hash representation of the specified key.
    #
    # @param [String] key the key to hash.
    def get_hash(key)
      (Zlib.crc32(key).abs % 100).to_s(36)
    end

    # Look up the offset for the specified key.
    #
    # @param [String] key
    # @return [Integer, NilClass] the offset, OR nil if the key was not found.
    def lookup_key(key)
      hash = get_hash(key)
      path = File.join(@index_folder, "#{hash}.index")
      @logger.fine("Using index file '#{path}'")
      return nil unless File.exist?(path)

      index_data = []
      File.open(path, 'rb') do |f|
        timestamp = read_int(0, f)
        raise IndexError.new('Index is out of date') if timestamp != @data_timestamp
        index_data = f.read
      end

      it = index_data.each_byte
      while it.peek
        k = unpack_string(it) # First read a null terminated string.
        o = unpack_int(it) # Then a long that represents the offset.
        return o if k.eql?(key) # If the string and key match, then the long is the required offset.
        return nil if k > key # If the unpacked key is greater than the required key, we can return immediately.
      end
    rescue StopIteration
      # EOF without finding anything.
    rescue IndexError
      raise IndexError.new("Error encountered while processing index file '#{path}'", $!)
    end

    # Reads a null-terminated string from the specified iterator.
    #
    # @param [Enumerator] it
    # @return [String]
    def unpack_string(it)
      string = []
      while (byte = it.next) != 0
        string << byte
      end
      string.pack('c*')
    rescue StopIteration
      raise IndexError.new('Unexpected end of index data while reading null-terminated string')
    end

    # Reads a 4-byte integer from the specified iterator.
    #
    # @param [Enumerator] it
    # @return [Integer]
    def unpack_int(it)
      int = [it.next, it.next, it.next, it.next]
      int.pack('c*').unpack('L')[0]
    rescue StopIteration
      raise IndexError.new('Unexpected end of index data while reading integer')
    end

  end

end
