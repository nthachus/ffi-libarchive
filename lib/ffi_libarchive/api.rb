# frozen_string_literal: true

require 'ffi'

module Archive
  module C
    def self.attach_function_maybe(*args)
      attach_function(*args)
    rescue FFI::NotFoundError # rubocop:disable all
    end

    extend FFI::Library
    ffi_lib ENV['ARCHIVE_LIB'] || %w[libarchive.so.13 libarchive.13 libarchive-13 libarchive.so libarchive archive]

    attach_function :archive_version_number, [], :int
    attach_function :archive_version_string, [], :string
    attach_function :archive_error_string, [:pointer], :string
    attach_function :archive_errno, [:pointer], :int

    attach_function :archive_read_new, [], :pointer
    attach_function :archive_read_open_filename, [:pointer, :string, :size_t], :int
    attach_function :archive_read_open_memory, [:pointer, :pointer, :size_t], :int
    attach_function :archive_read_open1, [:pointer], :int
    attach_function_maybe :archive_read_support_compression_program, [:pointer, :string], :int
    attach_function_maybe :archive_read_support_compression_all, [:pointer], :int

    # la_ssize_t archive_read_callback(struct archive *, void *_client_data, const void **_buffer)
    callback :archive_read_callback, [:pointer, :pointer, :pointer], :ssize_t
    callback :archive_skip_callback, [:pointer, :pointer, :int64], :int64
    callback :archive_seek_callback, [:pointer, :pointer, :int64, :int], :int64
    attach_function :archive_read_set_read_callback, [:pointer, :archive_read_callback], :int
    attach_function :archive_read_set_callback_data, [:pointer, :pointer], :int
    attach_function :archive_read_set_skip_callback, [:pointer, :archive_skip_callback], :int
    attach_function :archive_read_set_seek_callback, [:pointer, :archive_seek_callback], :int

    # @deprecated 4 methods below are unused
    # attach_function_maybe :archive_read_set_format, [:pointer, :int], :int
    # attach_function_maybe :archive_read_append_filter, [:pointer, :int], :int
    # attach_function_maybe :archive_read_append_filter_program, [:pointer, :string], :int
    # attach_function_maybe :archive_read_append_filter_program_signature, [:pointer, :string, :pointer, :size_t], :int

    attach_function_maybe :archive_read_support_filter_all, [:pointer], :int
    # @deprecated 16 archive_read_support_filter* methods below are unused
    # attach_function_maybe :archive_read_support_filter_bzip2, [:pointer], :int
    # attach_function_maybe :archive_read_support_filter_compress, [:pointer], :int
    # attach_function_maybe :archive_read_support_filter_gzip, [:pointer], :int
    # attach_function_maybe :archive_read_support_filter_grzip, [:pointer], :int
    # attach_function_maybe :archive_read_support_filter_lrzip, [:pointer], :int
    # attach_function_maybe :archive_read_support_filter_lz4, [:pointer], :int
    # attach_function_maybe :archive_read_support_filter_lzip, [:pointer], :int
    # attach_function_maybe :archive_read_support_filter_lzma, [:pointer], :int
    # attach_function_maybe :archive_read_support_filter_lzop, [:pointer], :int
    # attach_function_maybe :archive_read_support_filter_none, [:pointer], :int
    # attach_function_maybe :archive_read_support_filter_program, [:pointer], :int
    # attach_function_maybe :archive_read_support_filter_program_signature, [:pointer, :string, :pointer, :size_t], :int
    # attach_function_maybe :archive_read_support_filter_rpm, [:pointer], :int
    # attach_function_maybe :archive_read_support_filter_uu, [:pointer], :int
    # attach_function_maybe :archive_read_support_filter_xz, [:pointer], :int
    # attach_function_maybe :archive_read_support_filter_zstd, [:pointer], :int

    attach_function_maybe :archive_read_support_format_all, [:pointer], :int
    # @deprecated 19 archive_read_support_format_* methods below are unused
    # attach_function_maybe :archive_read_support_format_7zip, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_ar, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_by_code, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_cab, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_cpio, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_empty, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_gnutar, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_iso9660, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_lha, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_mtree, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_rar, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_rar5, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_raw, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_tar, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_warc, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_xar, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_zip, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_zip_streamable, [:pointer], :int
    # attach_function_maybe :archive_read_support_format_zip_seekable, [:pointer], :int

    begin
      attach_function :archive_read_free, [:pointer], :int
    rescue FFI::NotFoundError
      attach_function :archive_read_free, :archive_read_finish, [:pointer], :int
    end
    attach_function :archive_read_extract, [:pointer, :pointer, :int], :int
    attach_function :archive_read_header_position, [:pointer], :int64
    # int archive_read_next_header(struct archive *, struct archive_entry **)
    attach_function :archive_read_next_header, [:pointer, :pointer], :int
    attach_function :archive_read_data, [:pointer, :pointer, :size_t], :ssize_t
    attach_function :archive_read_data_into_fd, [:pointer, :int], :int
    attach_function_maybe :archive_read_data_skip, [:pointer], :int

    attach_function :archive_write_new, [], :pointer
    attach_function :archive_write_open_filename, [:pointer, :string], :int
    callback :archive_open_callback, [:pointer, :pointer], :int
    callback :archive_write_callback, [:pointer, :pointer, :pointer, :size_t], :int
    callback :archive_close_callback, [:pointer, :pointer], :int
    attach_function(
      :archive_write_open,
      [:pointer, :pointer, :archive_open_callback, :archive_write_callback, :archive_close_callback],
      :int
    )

    attach_function_maybe :archive_write_set_compression_none, [:pointer], :int
    attach_function_maybe :archive_write_set_compression_gzip, [:pointer], :int
    attach_function_maybe :archive_write_set_compression_bzip2, [:pointer], :int
    attach_function_maybe :archive_write_set_compression_lzip, [:pointer], :int
    attach_function_maybe :archive_write_set_compression_compress, [:pointer], :int
    attach_function_maybe :archive_write_set_compression_lzma, [:pointer], :int
    attach_function_maybe :archive_write_set_compression_xz, [:pointer], :int
    attach_function_maybe :archive_write_set_compression_program, [:pointer, :string], :int

    # @param [Pointer] archive
    # @return [Integer]
    def self.archive_write_set_compression(archive, compression)
      case compression
      when String
        archive_write_set_compression_program archive, compression
      when COMPRESSION_BZIP2
        archive_write_set_compression_bzip2 archive
      when COMPRESSION_GZIP
        archive_write_set_compression_gzip archive
      when COMPRESSION_LZIP
        archive_write_set_compression_lzip archive
      when COMPRESSION_LZMA
        archive_write_set_compression_lzma archive
      when COMPRESSION_XZ
        archive_write_set_compression_xz archive
      when COMPRESSION_COMPRESS
        archive_write_set_compression_compress archive
      when COMPRESSION_NONE
        archive_write_set_compression_none archive
      else
        raise "Unknown compression type: #{compression}"
      end
    end

    attach_function_maybe :archive_write_add_filter, [:pointer, :int], :int
    attach_function :archive_write_set_format, [:pointer, :int], :int
    attach_function :archive_write_data, [:pointer, :pointer, :size_t], :ssize_t
    attach_function :archive_write_header, [:pointer, :pointer], :int
    begin
      attach_function :archive_write_free, [:pointer], :int
    rescue FFI::NotFoundError
      attach_function :archive_write_free, :archive_write_finish, [:pointer], :int
    end
    attach_function :archive_write_get_bytes_in_last_block, [:pointer], :int
    attach_function :archive_write_set_bytes_in_last_block, [:pointer, :int], :int

    # region Entry APIs
    attach_function :archive_entry_new, [], :pointer
    attach_function :archive_entry_free, [:pointer], :void

    attach_function :archive_entry_atime, [:pointer], :time_t
    attach_function :archive_entry_atime_nsec, [:pointer], :long
    attach_function_maybe :archive_entry_atime_is_set, [:pointer], :int
    attach_function :archive_entry_set_atime, [:pointer, :time_t, :long], :void
    attach_function_maybe :archive_entry_unset_atime, [:pointer], :void

    attach_function_maybe :archive_entry_birthtime, [:pointer], :time_t
    attach_function_maybe :archive_entry_birthtime_nsec, [:pointer], :long
    attach_function_maybe :archive_entry_birthtime_is_set, [:pointer], :int
    attach_function_maybe :archive_entry_set_birthtime, [:pointer, :time_t, :long], :void
    attach_function_maybe :archive_entry_unset_birthtime, [:pointer], :void

    attach_function :archive_entry_ctime, [:pointer], :time_t
    attach_function :archive_entry_ctime_nsec, [:pointer], :long
    attach_function_maybe :archive_entry_ctime_is_set, [:pointer], :int
    attach_function :archive_entry_set_ctime, [:pointer, :time_t, :long], :void
    attach_function_maybe :archive_entry_unset_ctime, [:pointer], :void

    attach_function :archive_entry_mtime, [:pointer], :time_t
    attach_function :archive_entry_mtime_nsec, [:pointer], :long
    attach_function_maybe :archive_entry_mtime_is_set, [:pointer], :int
    attach_function :archive_entry_set_mtime, [:pointer, :time_t, :long], :void
    attach_function_maybe :archive_entry_unset_mtime, [:pointer], :void

    attach_function :archive_entry_dev, [:pointer], :dev_t
    attach_function :archive_entry_set_dev, [:pointer, :dev_t], :void
    attach_function :archive_entry_devmajor, [:pointer], :dev_t
    attach_function :archive_entry_set_devmajor, [:pointer, :dev_t], :void
    attach_function :archive_entry_devminor, [:pointer], :dev_t
    attach_function :archive_entry_set_devminor, [:pointer, :dev_t], :void

    attach_function :archive_entry_filetype, [:pointer], :mode_t
    attach_function :archive_entry_set_filetype, [:pointer, :uint], :void
    # void archive_entry_fflags(struct archive_entry *, unsigned long *set, unsigned long *clear)
    attach_function :archive_entry_fflags, [:pointer, :pointer, :pointer], :void
    attach_function :archive_entry_set_fflags, [:pointer, :ulong, :ulong], :void
    attach_function :archive_entry_fflags_text, [:pointer], :string
    attach_function :archive_entry_copy_fflags_text, [:pointer, :string], :string

    attach_function :archive_entry_gid, [:pointer], :int64_t
    attach_function :archive_entry_set_gid, [:pointer, :int64_t], :void
    attach_function :archive_entry_gname, [:pointer], :string
    attach_function :archive_entry_set_gname, [:pointer, :string], :void
    attach_function :archive_entry_copy_gname, [:pointer, :string], :void

    attach_function :archive_entry_hardlink, [:pointer], :string
    attach_function :archive_entry_set_hardlink, [:pointer, :string], :void
    attach_function :archive_entry_copy_hardlink, [:pointer, :string], :void
    attach_function :archive_entry_set_link, [:pointer, :string], :void
    attach_function :archive_entry_copy_link, [:pointer, :string], :void

    attach_function :archive_entry_ino, [:pointer], :int64_t
    attach_function :archive_entry_set_ino, [:pointer, :int64_t], :void

    attach_function :archive_entry_mode, [:pointer], :mode_t
    attach_function :archive_entry_set_mode, [:pointer, :mode_t], :void
    attach_function :archive_entry_perm, [:pointer], :mode_t
    attach_function :archive_entry_set_perm, [:pointer, :mode_t], :void
    attach_function :archive_entry_strmode, [:pointer], :string

    attach_function :archive_entry_nlink, [:pointer], :uint
    attach_function :archive_entry_set_nlink, [:pointer, :uint], :void

    attach_function :archive_entry_pathname, [:pointer], :string
    attach_function :archive_entry_set_pathname, [:pointer, :string], :void
    attach_function_maybe :archive_entry_pathname_w, [:pointer], :pointer
    attach_function_maybe :archive_entry_copy_pathname_w, [:pointer, :buffer_in], :void
    attach_function :archive_entry_copy_pathname, [:pointer, :string], :void

    attach_function :archive_entry_rdev, [:pointer], :dev_t
    attach_function :archive_entry_set_rdev, [:pointer, :dev_t], :void
    attach_function :archive_entry_rdevmajor, [:pointer], :dev_t
    attach_function :archive_entry_set_rdevmajor, [:pointer, :dev_t], :void
    attach_function :archive_entry_rdevminor, [:pointer], :dev_t
    attach_function :archive_entry_set_rdevminor, [:pointer, :dev_t], :void

    attach_function :archive_entry_size, [:pointer], :int64_t
    attach_function :archive_entry_set_size, [:pointer, :int64_t], :void
    attach_function_maybe :archive_entry_unset_size, [:pointer], :void
    attach_function_maybe :archive_entry_size_is_set, [:pointer], :int

    attach_function :archive_entry_sourcepath, [:pointer], :string
    attach_function :archive_entry_copy_sourcepath, [:pointer, :string], :void

    attach_function :archive_entry_symlink, [:pointer], :string
    attach_function :archive_entry_set_symlink, [:pointer, :string], :void
    attach_function :archive_entry_copy_symlink, [:pointer, :string], :void

    attach_function :archive_entry_uid, [:pointer], :int64_t
    attach_function :archive_entry_set_uid, [:pointer, :int64_t], :void
    attach_function :archive_entry_uname, [:pointer], :string
    attach_function :archive_entry_set_uname, [:pointer, :string], :void
    attach_function :archive_entry_copy_uname, [:pointer, :string], :void

    attach_function :archive_entry_stat, [:pointer], :pointer
    attach_function :archive_entry_copy_stat, [:pointer, :pointer], :void

    attach_function :archive_entry_xattr_clear, [:pointer], :void
    attach_function :archive_entry_xattr_add_entry, [:pointer, :string, :pointer, :size_t], :void
    attach_function :archive_entry_xattr_count, [:pointer], :int
    attach_function :archive_entry_xattr_reset, [:pointer], :int
    # int archive_entry_xattr_next(struct archive_entry *, const char **name, const void **value, size_t *)
    attach_function :archive_entry_xattr_next, [:pointer, :pointer, :pointer, :pointer], :int
    # endregion

    # region Error Codes
    EOF    = 1
    OK     = 0
    RETRY  = -10
    WARN   = -20
    FAILED = -25
    FATAL  = -30
    # endregion

    DATA_BUFFER_SIZE = 2**16
  end
end
