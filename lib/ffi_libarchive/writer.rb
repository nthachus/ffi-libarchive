# frozen_string_literal: true

module Archive
  class Writer < BaseArchive
    private_class_method :new

    def self.open_filename(file_name, compression, format)
      if block_given?
        writer = open_filename file_name, compression, format
        begin
          yield writer
        ensure
          writer.close
        end
      else
        new file_name: file_name, compression: compression, format: format
      end
    end

    def self.open_memory(string, compression, format)
      if block_given?
        writer = open_memory string, compression, format
        begin
          yield writer
        ensure
          writer.close
        end
      else
        # compression = -1 unless compression.is_a?(Integer)
        new memory: string, compression: compression, format: format
      end
    end

    def initialize(params = {})
      super C.method(:archive_write_new), C.method(:archive_write_finish)

      compression = params[:compression]
      compression = Archive.const_get("COMPRESSION_#{compression}".upcase) unless compression.is_a?(Integer)

      format = params[:format]
      format = Archive.const_get("FORMAT_#{format}".upcase) unless format.is_a?(Integer)

      raise Error, archive if C.archive_write_set_compression(archive, compression) != C::OK
      raise Error, archive if C.archive_write_set_format(archive, format) != C::OK

      if params[:file_name]
        raise Error, archive if C.archive_write_open_filename(archive, params[:file_name]) != C::OK
      elsif params[:memory]
        C.archive_write_set_bytes_in_last_block(archive, 1) if C.archive_write_get_bytes_in_last_block(archive) < 0

        @data = write_callback params[:memory]
        raise Error, archive if C.archive_write_open(archive, nil, nil, @data, nil) != C::OK
      end
    rescue StandardError
      close
      raise
    end

    def new_entry
      entry = Entry.new
      if block_given?
        begin
          yield entry
        ensure
          entry.close
        end
      else
        entry
      end
    end

    def add_entry
      raise ArgumentError, 'No block given' unless block_given?

      entry = Entry.new
      data = yield entry
      if data
        entry.size = data.bytesize
        write_header entry
        write_data data
      else
        write_header entry
      end
      nil
    ensure
      entry.close
    end

    def write_data(*args)
      if block_given?
        raise ArgumentError, "wrong number of argument (#{args.size} for 0)" unless args.empty?

        ar = archive
        len = 0
        loop do
          str = yield
          n = C.archive_write_data(ar, str, str.bytesize)
          return len if n < 1

          len += n
        end
      else
        raise ArgumentError, "wrong number of argument (#{args.size}) for 1)" if args.empty?

        str = args[0]
        C.archive_write_data(archive, str, str.bytesize)
      end
    end

    def write_header(entry)
      raise Error, archive if C.archive_write_header(archive, entry.entry) != C::OK
    end

    private

    def write_callback(data)
      proc do |_ar, _client, buffer, length|
        data << buffer.get_bytes(0, length)
        length
      end
    end
  end
end
