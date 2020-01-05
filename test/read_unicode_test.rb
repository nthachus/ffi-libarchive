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
      verify_content(ar)
    end
  end

  private

  # @param [Archive::Reader] arc
  def verify_content(arc)
    content_spec_idx = 0

    while (entry = arc.next_header)
      expect_pathname, expect_type, expect_mode, expect_content = CONTENT_SPEC[content_spec_idx]

      assert_equal expect_pathname, (entry.pathname_w || entry.pathname).encode(expect_pathname.encoding)
      assert entry.send("#{expect_type}?")
      assert_equal expect_mode, (entry.mode & 0o7777)
      assert_equal expect_type, entry.filetype_s

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
end
