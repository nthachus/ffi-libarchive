# frozen_string_literal: true

require 'ffi'

module Archive
  module Utils
    module LibC
      extend FFI::Library
      ffi_lib FFI::Library::LIBC

      # @!method mbstowcs(dest, src, max)
      #   Convert multibyte string to wide-character string
      #   @param [Pointer] dest of :wchar_t*
      #   @param [String] src
      #   @param [Integer] max  Maximum number of :wchar_t characters to write to dest
      #   @return [Integer] Number of wide characters written to dest (excluding null-terminated), or -1 if error
      attach_function :mbstowcs, [:pointer, :string, :size_t], :size_t

      # @!method chdir(path)
      #   Changes the current working directory
      #   @param [String] path
      #   @return [Integer] 0 if successful. Otherwise, -1
      begin
        attach_function :chdir, [:string], :int
      rescue FFI::NotFoundError
        attach_function :chdir, :_chdir, [:string], :int
      end

      # @!method strerror(errnum)
      #   Get error message string (see FFI.errno)
      #   @param [Integer] errnum
      #   @return [String]
      attach_function :strerror, [:int], :string
    end

    class << self
      # @return [String]
      def wchar_encoding
        @wchar_encoding ||=
          begin
            ptr = FFI::MemoryPointer.new 12
            rc = LibC.mbstowcs ptr, '!@', 3

            str = ptr.read_bytes 6
            enc = {
              'UTF-16LE' => "!\x00@\x00\x00\x00",
              'UTF-16BE' => "\x00!\x00@\x00\x00",
              'UTF-32LE' => "!\x00\x00\x00@\x00",
              'UTF-32BE' => "\x00\x00\x00!\x00\x00"
            }.key(str)
            raise "Unsupported wide-character: #{rc} - #{str.inspect}" unless enc

            enc
          end
      end

      # @param [Pointer] ptr
      # @return [String]
      def read_wide_string(ptr)
        return nil if !ptr.respond_to?(:null?) || ptr.null?

        if wchar_encoding.include?('32')
          wchar_sz = 4
          wchar_t = :int32
        else
          wchar_sz = 2
          wchar_t = :int16
        end

        # detect string length in bytes
        sz = ptr.size
        sz -= wchar_sz if sz

        len = 0
        len += wchar_sz while (!sz || len < sz) && ptr.send("get_#{wchar_t}", len) != 0

        ptr.read_bytes(len).force_encoding(wchar_encoding)
      end

      # @param [String] str
      # @return [String]
      def to_wide_string(str)
        str ? str.encode(wchar_encoding) : str
      end

      # @param [String] dir
      # @return [Integer]
      def change_cwd(dir)
        if block_given?
          cwd = Dir.getwd
          change_cwd dir

          begin
            yield
          ensure
            change_cwd cwd
          end
        else
          rc = Dir.chdir dir
          rc != 0 ? rc : LibC.chdir(dir)
        end
      end

      # @param [Integer] errno
      # @return [String]
      def error_message(errno = nil)
        errno ||= FFI.errno
        errno ? LibC.strerror(errno) : nil
      end
    end
  end
end
