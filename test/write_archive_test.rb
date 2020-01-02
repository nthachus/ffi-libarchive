# frozen_string_literal: true

require 'test_helper'
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

  private

  def write_content(arc)
    CONTENT_SPEC.each do |spec|
      entry_path, entry_type, entry_mode, entry_content = spec

      arc.new_entry do |entry|
        entry.pathname = entry_path
        entry.mode = entry_mode
        entry.filetype = Archive::Entry.const_get(entry_type.to_s.upcase)
        entry.size = entry_content.size if entry_content
        entry.symlink = entry_content if entry_type == :symbolic_link
        entry.atime = Time.now.to_i
        entry.mtime = Time.now.to_i

        arc.write_header(entry)
        arc.write_data(entry_content) if entry_type == :file
      end
    end
  end

  def verify_content_memory(memory)
    assert memory && !memory.empty?

    Archive.read_open_memory(memory) do |ar|
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

  def verify_content(filename)
    assert filename && File.exist?(filename)

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
