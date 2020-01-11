# frozen_string_literal: true

require 'tmpdir'

class WriteArchiveTest < Test::Unit::TestCase
  include TestHelper

  def test_end_to_end_write_read_tar_gz
    Dir.mktmpdir do |dir|
      filename = File.join(dir, 'test.tar.gz')
      Archive.write_open_filename(filename, :gzip, :tar) do |ar|
        write_content(ar)
      end

      verify_content(filename)
    end
  end

  def test_end_to_end_write_read_memory
    memory = String.new
    Archive.write_open_memory(memory, Archive::COMPRESSION_GZIP, Archive::FORMAT_TAR) do |ar|
      write_content ar
    end

    verify_content_memory(memory)
  end

  def test_end_to_end_write_read_tar_gz_with_external_gzip
    Dir.mktmpdir do |dir|
      filename = File.join(dir, 'test.tar.gz')
      Archive.write_open_filename(filename, 'gzip', :tar) do |ar|
        write_content(ar)
      end

      verify_content(filename)
    end
  end

  def test_write_entry_with_multiple_chunks
    content    = 'foo ' * 1000
    entry_size = content.bytesize

    Dir.mktmpdir do |dir|
      filename = File.join(dir, 'test.tar.xz')

      compress_content_by_chunks(filename, content)
      assert File.exist?(filename)

      # @type [Archive::Reader] ar
      Archive.read_open_filename(filename) do |ar|
        entry = ar.next_header
        data  = ar.read_data

        # noinspection RubyNilAnalysis
        assert_equal entry_size, entry.size
        assert_equal entry_size, data.bytesize
      end
    end
  end

  private

  # @param [String] filename
  # @param [String] content
  def compress_content_by_chunks(filename, content)
    # @type [Archive::Writer] ar
    Archive.write_open_filename(filename, Archive::FILTER_XZ, Archive::FORMAT_TAR) do |ar|
      entry = ar.new_entry
      begin
        # noinspection RubyNilAnalysis
        entry.pathname = 'chubby.dat'
        entry.mode     = 0o644
        entry.filetype = Archive::Entry::FILE
        entry.mtime    = Time.now
        entry.size     = content.bytesize

        ar.write_header entry
        len = ar.write_data do |i|
          content.slice!(0, i) if i > 0
          content
        end

        assert_equal entry.size, len
      ensure
        entry.close
      end
    end
  end

  # @param [Archive::Writer] arc
  def write_content(arc)
    CONTENT_SPEC.each do |spec|
      entry_path, entry_type, entry_mode, entry_content = spec

      # @type [Archive::Entry] entry
      arc.add_entry do |entry|
        entry.pathname = entry_path
        entry.mode     = entry_mode
        entry.filetype = entry_type
        entry.symlink  = entry_content if entry_type == :symbolic_link
        entry.atime    = Time.now
        entry.mtime    = Time.now
        entry.size     = entry_content.size if entry_content && entry_type != :file

        entry_type == :file ? entry_content : nil
      end
    end
  end

  # @param [String] memory
  def verify_content_memory(memory)
    assert memory && !memory.empty?

    # @type [Archive::Reader] ar
    Archive.read_open_memory(memory) do |ar|
      content_spec_idx = 0

      ar.each_entry do |entry|
        expect_pathname, expect_type, expect_mode, expect_content = CONTENT_SPEC[content_spec_idx]

        # noinspection RubyNilAnalysis
        assert_equal expect_pathname, entry.pathname
        assert entry.send("#{expect_type}?")
        assert_equal expect_mode, (entry.mode & 0o7777)

        if entry.symbolic_link?
          assert_equal expect_content, entry.symlink
        elsif entry.file?
          content = ar.read_data(1024)
          assert_equal expect_content, content
        end

        content_spec_idx += 1
      end
    end
  end

  # @param [String] filename
  def verify_content(filename)
    assert filename && File.exist?(filename)

    # @type [Archive::Reader] ar
    Archive.read_open_filename(filename) do |ar|
      content_spec_idx = 0

      while (entry = ar.next_header)
        expect_pathname, expect_type, expect_mode, expect_content = CONTENT_SPEC[content_spec_idx]

        assert_equal expect_pathname, entry.pathname
        assert entry.send("#{expect_type}?")
        assert_equal expect_mode, (entry.mode & 0o7777)

        if entry.symbolic_link?
          assert_equal expect_content, entry.symlink
        elsif entry.file?
          content = ar.read_data(1024)
          assert_equal expect_content, content
        end

        content_spec_idx += 1
      end
    end
  end
end
