# frozen_string_literal: true

require 'securerandom'
require 'tmpdir'

class ReadArchiveTest < Test::Unit::TestCase
  include TestHelper

  def test_read_tar_gz_from_file
    Archive.read_open_filename(fixture_path('test.tar.gz')) do |ar|
      verify_content(ar)
    end
  end

  def test_read_tar_gz_from_file_with_external_gunzip
    Archive.read_open_filename(fixture_path('test.tar.gz'), 'gzip -d') do |ar|
      verify_content(ar)
    end
  end

  def test_read_tar_gz_from_memory
    Archive.read_open_memory(archive_content) do |ar|
      verify_content(ar)
    end
  end

  def test_read_tar_gz_from_memory_with_external_gunzip
    Archive.read_open_memory(archive_content, 'gzip -d') do |ar|
      verify_content(ar)
    end
  end

  def test_read_entry_bigger_than_internal_buffer
    entry_size = 1024 * 4 - 3
    # @type [String]
    content = SecureRandom.urlsafe_base64(entry_size)[0, entry_size]

    Dir.mktmpdir do |dir|
      filename = File.join(dir, 'test.tar.gz')

      write_content filename, content
      assert File.exist?(filename)

      Archive.read_open_filename(filename) do |ar|
        ar.next_header
        data = ar.read_data

        assert_equal entry_size, data.size
        assert_equal content, data
      end

      Archive.read_open_filename(filename) do |ar|
        ar.next_header
        data = String.new
        ar.read_data(128) { |chunk| data << chunk }

        assert_equal entry_size, data.size
        assert_equal content, data
      end
    end
  end

  def test_extract_no_additional_flags
    Dir.mktmpdir do |dir|
      Archive.read_open_filename(fixture_path('test.tar.gz')) do |ar|
        Archive::Utils.change_cwd(dir) do
          ar.each_entry do |e|
            next if e.symbolic_link? && FFI::Platform.windows?

            ar.extract(e)

            assert File.exist?(e.pathname)
            refute_equal File.mtime(e.pathname), e.mtime
          end
        end
      end
    end
  end

  def test_extract_extract_time
    Dir.mktmpdir do |dir|
      Archive.read_open_filename(fixture_path('test.tar.gz')) do |ar|
        Archive::Utils.change_cwd(dir) do
          ar.each_entry do |e|
            next if e.symbolic_link? && FFI::Platform.windows?

            ar.extract(e, Archive::EXTRACT_TIME)

            assert File.exist?(e.pathname)
            assert_equal File.mtime(e.pathname), e.mtime unless e.directory? || e.symbolic_link?
          end
        end
      end
    end
  end

  def test_read_from_stream_with_proc
    reader = TestReader.new

    Archive.read_open_stream(reader.method(:call).to_proc) do |ar|
      verify_content(ar)
    end
  end

  class TestReader
    # @!visibility protected
    # @return [File]
    attr_reader :fp

    def initialize(filename = 'test.tar.gz')
      @fp = File.open(TestHelper.fixture_path(filename), 'rb')

      if block_given?
        begin
          yield self
        ensure
          close
        end
      else
        ObjectSpace.define_finalizer(self, method(:close).to_proc)
      end
    end

    def call
      fp.read(32)
    end

    def close
      @fp.close if @fp.respond_to?(:close)
    ensure
      @fp = nil
    end
  end

  def test_read_from_stream_with_object
    TestReader.new do |reader|
      Archive.read_open_stream(reader) do |ar|
        verify_content(ar)
      end
    end
  end

  class SkipNSeekTestReader < TestReader
    attr_reader :skip_called, :seek_called

    def initialize(filename = 'test.zip')
      super
    end

    def skip(offset)
      @skip_called = true

      orig_pos = fp.tell
      fp.seek(offset, :CUR)
      fp.tell - orig_pos
    end

    def seek(offset, whence)
      @seek_called = true

      fp.seek(offset, whence)
      fp.tell
    end
  end

  def test_read_from_stream_with_skip_seek_object
    expect_pathname, expect_type, _, expect_content = CONTENT_SPEC[6]
    verified = false
    reader = SkipNSeekTestReader.new

    Archive.read_open_stream(reader) do |ar|
      ar.each_entry do |entry|
        next unless entry.pathname == expect_pathname

        verified = true

        assert_equal expect_pathname, entry.pathname
        assert entry.send("#{expect_type}?")
        # Skip verifying file mode; Zip files doesn't store it.

        assert entry.file?
        content = ar.read_data(1024)
        assert_equal expect_content, content
      end
    end

    assert verified
    assert reader.skip_called
    assert reader.seek_called
  end

  private

  # @return [String]
  def archive_content
    @archive_content ||= File.read(fixture_path('test.tar.gz'), mode: 'rb')
  end

  # @param [String] filename
  # @param [String] content
  def write_content(filename, content)
    Archive.write_open_filename(filename, Archive::COMPRESSION_BZIP2, Archive::FORMAT_TAR) do |ar|
      ar.new_entry do |entry|
        entry.pathname = 'chubby.dat'
        entry.mode = 0o666
        entry.filetype = Archive::Entry::FILE
        entry.atime = Time.now
        entry.mtime = Time.now
        entry.size = content.bytesize

        ar.write_header(entry)
        ar.write_data(content)
      end
    end
  end

  def verify_content(arc)
    content_spec_idx = 0

    while (entry = arc.next_header)
      expect_pathname, expect_type, expect_mode, expect_content = CONTENT_SPEC[content_spec_idx]

      assert_equal expect_pathname, entry.pathname
      assert entry.send("#{expect_type}?")
      assert_equal expect_mode, (entry.mode & 0o7777)

      if entry.symbolic_link?
        assert_equal expect_content, entry.symlink
      elsif entry.file?
        content = arc.read_data(1024)
        assert_equal expect_content, content
      end

      content_spec_idx += 1
    end
  end
end
