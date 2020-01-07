# encoding: UTF-8
# frozen_string_literal: true

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
      assert_equal expect_type, entry.filetype_s

      verify_entry_stat entry, expect_mode, expect_content
      verify_copy_stat_to_entry entry, expect_pathname if entry.file?

      if entry.symbolic_link?
        assert_equal expect_content, entry.symlink
      elsif entry.file?
        content = arc.read_data(1024)
        assert_equal expect_content, content
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

    s = st.read_bytes(144).reverse.unpack('H*').first
    assert_include s, expect_mode.to_s(16)
    assert_include s, expect_content.bytesize.to_s(16) if entry.file?
    assert_include s, expect_content.to_s(16) if entry.directory?
  end

  # @param [Archive::Entry] entry
  def verify_copy_stat_to_entry(entry, expect_pathname)
    assert_equal expect_pathname, entry.pathname_w.encode(expect_pathname.encoding)
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
end
