# frozen_string_literal: true

module Archive
  # Stream filter Codes
  FILTER_NONE     = 0
  FILTER_GZIP     = 1
  FILTER_BZIP2    = 2
  FILTER_COMPRESS = 3
  FILTER_PROGRAM  = 4
  FILTER_LZMA     = 5
  FILTER_XZ       = 6
  FILTER_UU       = 7
  FILTER_RPM      = 8
  FILTER_LZIP     = 9
  FILTER_LRZIP    = 10
  FILTER_LZOP     = 11
  FILTER_GRZIP    = 12
  FILTER_LZ4      = 13
  FILTER_ZSTD     = 14
  # endregion

  # region Compression Codes (deprecated)
  COMPRESSION_NONE     = FILTER_NONE
  COMPRESSION_GZIP     = FILTER_GZIP
  COMPRESSION_BZIP2    = FILTER_BZIP2
  COMPRESSION_COMPRESS = FILTER_COMPRESS
  COMPRESSION_PROGRAM  = FILTER_PROGRAM
  COMPRESSION_LZMA     = FILTER_LZMA
  COMPRESSION_XZ       = FILTER_XZ
  COMPRESSION_UU       = FILTER_UU
  COMPRESSION_RPM      = FILTER_RPM
  COMPRESSION_LZIP     = FILTER_LZIP
  COMPRESSION_LRZIP    = FILTER_LRZIP
  # endregion

  # region Format Codes
  FORMAT_BASE_MASK           = 0xff0000
  FORMAT_CPIO                = 0x10000
  FORMAT_CPIO_POSIX          = (FORMAT_CPIO | 1)
  FORMAT_CPIO_BIN_LE         = (FORMAT_CPIO | 2)
  FORMAT_CPIO_BIN_BE         = (FORMAT_CPIO | 3)
  FORMAT_CPIO_SVR4_NOCRC     = (FORMAT_CPIO | 4)
  FORMAT_CPIO_SVR4_CRC       = (FORMAT_CPIO | 5)
  FORMAT_CPIO_AFIO_LARGE     = (FORMAT_CPIO | 6)
  FORMAT_SHAR                = 0x20000
  FORMAT_SHAR_BASE           = (FORMAT_SHAR | 1)
  FORMAT_SHAR_DUMP           = (FORMAT_SHAR | 2)
  FORMAT_TAR                 = 0x30000
  FORMAT_TAR_USTAR           = (FORMAT_TAR | 1)
  FORMAT_TAR_PAX_INTERCHANGE = (FORMAT_TAR | 2)
  FORMAT_TAR_PAX_RESTRICTED  = (FORMAT_TAR | 3)
  FORMAT_TAR_GNUTAR          = (FORMAT_TAR | 4)
  FORMAT_ISO9660             = 0x40000
  FORMAT_ISO9660_ROCKRIDGE   = (FORMAT_ISO9660 | 1)
  FORMAT_ZIP                 = 0x50000
  FORMAT_EMPTY               = 0x60000
  FORMAT_AR                  = 0x70000
  FORMAT_AR_GNU              = (FORMAT_AR | 1)
  FORMAT_AR_BSD              = (FORMAT_AR | 2)
  FORMAT_MTREE               = 0x80000
  FORMAT_RAW                 = 0x90000
  FORMAT_XAR                 = 0xA0000
  FORMAT_LHA                 = 0xB0000
  FORMAT_CAB                 = 0xC0000
  FORMAT_RAR                 = 0xD0000
  FORMAT_7ZIP                = 0xE0000
  FORMAT_WARC                = 0xF0000
  FORMAT_RAR_V5              = 0x100000
  # endregion

  # region Extraction Flags
  EXTRACT_OWNER              = 0x0001
  EXTRACT_PERM               = 0x0002
  EXTRACT_TIME               = 0x0004
  EXTRACT_NO_OVERWRITE       = 0x0008
  EXTRACT_UNLINK             = 0x0010
  EXTRACT_ACL                = 0x0020
  EXTRACT_FFLAGS             = 0x0040
  EXTRACT_XATTR              = 0x0080
  EXTRACT_SECURE_SYMLINKS    = 0x0100
  EXTRACT_SECURE_NODOTDOT    = 0x0200
  EXTRACT_NO_AUTODIR         = 0x0400
  EXTRACT_NO_OVERWRITE_NEWER = 0x0800
  EXTRACT_SPARSE             = 0x1000
  EXTRACT_MAC_METADATA       = 0x2000
  EXTRACT_NO_HFS_COMPRESSION = 0x4000
  EXTRACT_HFS_COMPRESSION_FORCED = 0x8000
  EXTRACT_SECURE_NOABSOLUTEPATHS = 0x10000
  EXTRACT_CLEAR_NOCHANGE_FFLAGS  = 0x20000
  # endregion

  class << self
    # @param [String] file_name
    # @return [Reader]
    # @yieldparam [Reader]
    def read_open_filename(file_name, command = nil, &block)
      Reader.open_filename file_name, command, &block
    end

    # @param [String] string
    # @return [Reader]
    # @yieldparam [Reader]
    def read_open_memory(string, command = nil, &block)
      Reader.open_memory string, command, &block
    end

    # @param [#call] reader
    # @return [Reader]
    # @yieldparam [Reader]
    def read_open_stream(reader, command = nil, &block)
      Reader.open_stream reader, command, &block
    end

    # @param [String] file_name
    # @return [Writer]
    # @yieldparam [Writer]
    def write_open_filename(file_name, compression, format, &block)
      Writer.open_filename file_name, compression, format, &block
    end

    # @param [String] string
    # @return [Writer]
    # @yieldparam [Writer]
    def write_open_memory(string, compression, format, &block)
      Writer.open_memory string, compression, format, &block
    end

    # @return [Integer]
    def version_number
      C.archive_version_number
    end

    # @return [String]
    def version_string
      C.archive_version_string
    end
  end

  class Error < StandardError
    # noinspection RubyNilAnalysis
    def initialize(obj = nil)
      super(obj.respond_to?(:error_string) ? obj.error_string : obj)
    end
  end

  # @abstract
  class BaseArchive
    # @param [Method] alloc
    # @param [Method] free
    def initialize(alloc, free)
      raise ArgumentError, 'Invalid methods' unless alloc.respond_to?(:call) && free.respond_to?(:call)

      @archive = alloc.call
      raise Error, 'No archive open' unless @archive

      @archive_free = [free]
      ObjectSpace.define_finalizer(self, method(:close).to_proc)
    end

    def close
      # TODO: do we need synchronization here?
      @archive_free[0].call(@archive) if @archive && @archive_free[0].respond_to?(:call) # TODO: Error check?
    ensure
      @archive = nil
      @archive_free[0] = nil
    end

    # @!visibility protected
    # @return [FFI::Pointer]
    attr_reader :archive

    # @return [String]
    def error_string
      C.archive_error_string(archive)
    end

    # @return [Integer]
    def errno
      C.archive_errno(archive)
    end
  end
end
