# frozen_string_literal: true

require 'tmpdir'

class ErrorCasesTest < Test::Unit::TestCase
  include TestHelper

  def test_create_auto_dispose_entry
    o = Archive::Entry.new { |e| assert e.entry }
    refute o.entry
  end

  def test_copy_lstat_for_entry
    filename = fixture_path('test.zip')

    Archive::Entry.new do |e|
      if FFI::Platform.windows?
        e.copy_lstat filename

        assert_operator 0, :<, e.size
        assert_equal File.size(filename), e.size
      else
        # :nocov:
        Dir.mktmpdir do |dir|
          path = File.join dir, 'link2test'
          File.symlink filename, path

          e.copy_lstat path

          assert_operator 0, :<, e.size
          assert_operator File.size(path), :>, e.size
        end
        # :nocov:
      end
    end
  end

  def test_copy_stat_struct_to_entry
    # @type [Archive::Entry] e
    Archive::Entry.new do |e|
      e.mode = 0o644

      # noinspection RubyResolve
      FFI::MemoryPointer.new(:char, 144) do |st|
        e.copy_stat st
      end

      assert_equal 0, e.mode
    end
  end

  def test_read_non_exist_archive_file
    assert_raise(Archive::Error) do
      Archive::Reader.open_filename fixture_path('non_exist')
    end
  end

  def test_read_with_invalid_compression_program
    assert_raise(Archive::Error) do
      Archive::Reader.open_filename fixture_path('test.zip'), 'x_x'
    end
  end

  def test_write_with_unsupported_compression
    Dir.mktmpdir do |dir|
      filename = File.join dir, 'test.zip'

      assert_raise(ArgumentError) { Archive::Writer.open_filename filename, nil, :zip }
      assert_raise(NameError) { Archive::Writer.open_filename filename, :x_x, :zip }
      assert_raise(Archive::Error) { Archive::Writer.open_filename filename, -1, :zip }
    end
  end

  def test_write_with_invalid_format
    Dir.mktmpdir do |dir|
      filename = File.join dir, 'test.zip'

      assert_raise(ArgumentError) { Archive::Writer.open_filename filename, :gzip, nil }
      assert_raise(NameError) { Archive::Writer.open_filename filename, :gzip, :x_x }
      assert_raise(Archive::Error) { Archive::Writer.open_filename filename, :gzip, -1 }
    end
  end
end
