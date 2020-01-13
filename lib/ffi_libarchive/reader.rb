# frozen_string_literal: true

module Archive
  class Reader < BaseArchive
    private_class_method :new

    # @param [String] file_name
    # @return [Reader]
    # @yieldparam [Reader]
    def self.open_filename(file_name, command = nil)
      if block_given?
        reader = open_filename file_name, command
        begin
          yield reader
        ensure
          reader.close if reader.respond_to?(:close)
        end
      else
        new file_name: file_name, command: command
      end
    end

    # @param [String] string
    # @return [Reader]
    # @yieldparam [Reader]
    def self.open_memory(string, command = nil)
      if block_given?
        reader = open_memory string, command
        begin
          yield reader
        ensure
          reader.close if reader.respond_to?(:close)
        end
      else
        new memory: string, command: command
      end
    end

    # @param [#call] stream
    # @return [Reader]
    # @yieldparam [Reader]
    def self.open_stream(stream, command = nil)
      if block_given?
        reader = open_stream stream, command
        begin
          yield reader
        ensure
          reader.close if reader.respond_to?(:close)
        end
      else
        new reader: stream, command: command
      end
    end

    # @param [Hash] params
    # @option params [Object] :command
    # @option params [String] :file_name
    # @option params [String] :memory
    # @option params [#call] :reader
    def initialize(params = {})
      super C.method(:archive_read_new), C.method(:archive_read_free)

      begin
        init_compression params[:command]
        init_format

        if params[:file_name]
          init_for_filename params[:file_name]
        elsif params[:memory]
          init_for_memory params[:memory]
        elsif params[:reader]
          init_for_stream params[:reader]
        end
      rescue StandardError
        close
        raise
      end
    end

    # @param [Entry] entry
    # @param [Integer] flags  see ::EXTRACT_*
    def extract(entry, flags = 0)
      raise ArgumentError, 'Expected Archive::Entry as first argument' unless entry.is_a? Entry
      raise ArgumentError, 'Expected Integer as second argument' unless flags.is_a? Integer

      flags |= EXTRACT_FFLAGS
      raise Error, self if C.archive_read_extract(archive, entry.entry, flags) != C::OK
    end

    # Retrieve the byte offset in UNCOMPRESSED data where last-read header started.
    # @return [Integer]
    def header_position
      C.archive_read_header_position archive
    end

    # @return [Entry]
    def next_header
      entry_ptr = FFI::MemoryPointer.new(:pointer)

      case C.archive_read_next_header(archive, entry_ptr)
      when C::OK
        Entry.from_pointer entry_ptr.get_pointer(0)
      when C::EOF
        nil
      else
        raise Error, self
      end
    end

    # @yieldparam [Entry]
    def each_entry
      while (entry = next_header)
        yield entry
      end
    end

    # @yieldparam [Entry] entry
    # @yieldparam [String] data
    def each_entry_with_data(size = C::DATA_BUFFER_SIZE)
      while (entry = next_header)
        yield entry, read_data(size)
      end
    end

    # @yieldparam [Entry] entry
    def each_entry_skip_data
      while (entry = next_header)
        begin
          yield entry
        ensure
          C.archive_read_data_skip archive
        end
      end
    end

    # @return [String, Integer]
    # @yieldparam [String] chunk
    def read_data(size = C::DATA_BUFFER_SIZE)
      raise ArgumentError, "Buffer size must be > 0 (was: #{size})" if !size.is_a?(Integer) || size <= 0

      data   = nil
      buffer = FFI::MemoryPointer.new(:char, size)
      len    = 0

      while (n = C.archive_read_data(archive, buffer, size)) != 0
        # TODO: C::FATAL, C::WARN, C::RETRY
        raise Error, self if n < 0

        chunk = buffer.get_bytes(0, n)
        if block_given?
          yield chunk
        elsif data
          data << chunk
        else
          data = chunk.dup
        end

        len += n
      end

      data || len
    end

    # @param [String] file_name
    def save_data(file_name)
      File.open(file_name, 'wb') do |f|
        raise Error, self if C.archive_read_data_into_fd(archive, f.fileno) != C::OK
      end
    end

    def close
      super
      @read_callback = nil
      @skip_callback = nil
      @seek_callback = nil
    end

    protected

    def init_compression(command)
      if command && !(cmd = command.to_s).empty?
        raise Error, self if C.archive_read_support_compression_program(archive, cmd) != C::OK
      elsif C.respond_to?(:archive_read_support_filter_all)
        raise Error, self if C.archive_read_support_filter_all(archive) != C::OK
      elsif C.archive_read_support_compression_all(archive) != C::OK
        raise Error, self
      end
    end

    def init_format
      raise Error, self if C.archive_read_support_format_all(archive) != C::OK
    end

    BLOCK_SIZE = 1024

    def init_for_filename(file_name)
      raise Error, self if C.archive_read_open_filename(archive, file_name, BLOCK_SIZE) != C::OK
    end

    def init_for_memory(string)
      buffer = Utils.get_memory_ptr(string)
      raise Error, self if C.archive_read_open_memory(archive, buffer, string.bytesize) != C::OK
    end

    def init_for_stream(reader)
      @read_callback = proc do |_ar, _client_data, buffer|
        # @type [String]
        data = reader.call

        if data.is_a?(String)
          buffer.put_pointer 0, Utils.get_memory_ptr(data)
          data.bytesize
        else
          0
        end
      end
      raise Error, self if C.archive_read_set_read_callback(archive, @read_callback) != C::OK

      if reader.respond_to?(:skip)
        @skip_callback = proc { |_ar, _client_data, request| reader.skip(request) }
        raise Error, self if C.archive_read_set_skip_callback(archive, @skip_callback) != C::OK
      end

      if reader.respond_to?(:seek)
        @seek_callback = proc { |_ar, _client_data, offset, whence| reader.seek(offset, whence) }
        raise Error, self if C.archive_read_set_seek_callback(archive, @seek_callback) != C::OK
      end

      # Required or open1 will segfault, even though the callback data is not used.
      raise Error, self if C.archive_read_set_callback_data(archive, FFI::Pointer::NULL) != C::OK
      raise Error, self if C.archive_read_open1(archive) != C::OK
    end
  end
end
