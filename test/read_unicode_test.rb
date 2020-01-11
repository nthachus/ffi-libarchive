# encoding: UTF-8
# frozen_string_literal: true

require 'tmpdir'

class ReadUnicodeTest < Test::Unit::TestCase
  include TestHelper

  CONTENT_SPEC = [
    ['a中Я/©Ðõ.txt', :file, 0o600, TestHelper.bin_string('©Ðõ')],
    ['a中Я/ταБЬℓσ/コンニチハ.dat', :file, 0o644, TestHelper.bin_string('Hello world, Καλημέρα κόσμε, コンニチハ')],
    ['a中Я/Καλημέρα.lnk', :symbolic_link, 0o777, TestHelper.bin_string('ταБЬℓσ/コンニチハ.dat')],
    ['a中Я/ταБЬℓσ/', :directory, 0o755, 1_578_226_739],
    ['a中Я/', :directory, 0o755, 1_578_226_739]
  ].freeze

  def test_read_7zip_with_unicode_contents
    Archive.read_open_filename(fixture_path('test.7z')) do |ar|
      assert_equal 0, ar.errno
      assert_empty Archive::Error.new(ar).message.tr('Archive::Error', '')

      verify_content(ar)
    end
  end

  def test_list_unicode_contents_for_7zip
    Archive.read_open_filename(fixture_path('test.7z')) do |ar|
      content_spec_idx = 0

      # @type [Archive::Entry] entry
      ar.each_entry_skip_data do |entry|
        expect_pathname, expect_type, expect_mode, expect_content = CONTENT_SPEC[content_spec_idx]

        assert_equal expect_pathname, entry.pathname_w.encode(expect_pathname.encoding)
        assert_equal expect_mode, (entry.mode & 0o7777)
        assert_equal expect_type, entry.filetype_s
        assert_equal expect_content, entry.symlink if entry.symbolic_link?

        verify_entry_extra entry

        content_spec_idx += 1
      end
    end
  end

  def test_read_7zip_file_fully
    Archive.read_open_filename(fixture_path('test.7z')) do |ar|
      content_spec_idx = 0

      # @type [Archive::Entry] entry
      ar.each_entry_with_data(32) do |entry, data|
        expect_pathname, expect_type, expect_mode, expect_content = CONTENT_SPEC[content_spec_idx]

        assert_equal expect_pathname, entry.pathname_w.encode(expect_pathname.encoding)
        assert_equal expect_mode, (entry.mode & 0o7777)
        assert_equal expect_type, entry.filetype_s

        if entry.symbolic_link?
          assert_equal expect_content, entry.symlink
        elsif entry.file?
          assert_equal expect_content, data
        elsif entry.directory?
          assert_equal 0, data
        end

        assert_operator 0, :<, ar.header_position if content_spec_idx.nonzero?
        content_spec_idx += 1
      end
    end
  end

  private

  # @param [Archive::Reader] arc
  def verify_content(arc)
    content_spec_idx = 0

    arc.each_entry do |entry|
      expect_pathname, expect_type, expect_mode, expect_content = CONTENT_SPEC[content_spec_idx]
      # noinspection RubyNilAnalysis
      pathname = FFI::Platform.windows? ? entry.pathname_w : entry.pathname.force_encoding('UTF-8')

      assert_equal expect_pathname, pathname.encode(expect_pathname.encoding)
      assert entry.send("#{expect_type}?")
      assert_equal expect_mode, (entry.mode & 0o7777)

      verify_entry_stat entry, expect_mode, expect_content
      verify_copy_stat_to_entry entry if entry.file?

      if entry.symbolic_link?
        assert_equal expect_content, entry.symlink
      elsif entry.file?
        Dir.mktmpdir do |dir|
          arc.save_data(path = File.join(dir, 'test.dat'))
          assert_equal expect_content, File.read(path, mode: 'rb')
        end
      elsif entry.directory?
        assert_equal Time.at(expect_content), entry.mtime
      end

      content_spec_idx += 1
    end
  end

  # @param [Archive::Entry] entry
  def verify_entry_stat(entry, expect_mode, expect_content)
    st = entry.stat
    assert st.respond_to?(:null?)
    refute st.null?
    assert_operator 144, :<=, st.size

    # noinspection RubyResolve
    s = st.get_bytes(0, 144).reverse.unpack('H*').first
    assert_include s, expect_mode.to_s(16)
    assert_include s, expect_content.bytesize.to_s(16) if entry.file?
    assert_include s, expect_content.to_s(16) if entry.directory?
  end

  # @param [Archive::Entry] entry
  def verify_copy_stat_to_entry(entry)
    assert_raise(ArgumentError) { entry.copy_stat nil }

    path = File.expand_path __FILE__
    entry.copy_stat path

    assert_equal File.size(path), entry.size
    assert_equal File.stat(path).mode, entry.mode

    %w[ctime mtime atime].each do |fn|
      ts = File.send fn, path
      assert_equal Time.at(ts.to_i), entry.send(fn)
      assert_equal ts.nsec, entry.send("#{fn}_nsec")
    end
  end

  # @param [Archive::Entry] entry
  def verify_entry_extra(entry)
    # noinspection SpellCheckingInspection
    assert_equal 'drwxr-xr-x ', entry.strmode.encode('UTF-8') if entry.directory?

    assert_equal [0, 0], entry.fflags
    assert_equal 0, entry.xattr_count

    entry.xattr_add_entry 'foo', 'bar'
    assert_equal 1, entry.xattr_reset
    assert_equal %w[foo bar], entry.xattr_next

    assert_equal 1, entry.xattr_count
    entry.xattr_clear
    assert_equal 0, entry.xattr_count
  end
end
