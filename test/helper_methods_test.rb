# frozen_string_literal: true

class HelperMethodsTest < Test::Unit::TestCase
  def test_lib_must_have_version_number
    ver = Archive.version_number
    assert ver.is_a?(Integer)
    assert_operator 0, :<, ver
  end

  def test_lib_must_have_version_string
    ver = Archive.version_string
    assert_instance_of String, ver
    assert_match(/\b\d+(\.\d+)+\b/, ver)
  end

  def test_convert_to_wide_string
    s = File.basename __FILE__
    ws = Archive::Utils.to_wide_string s

    refute_equal s.encoding, ws.encoding
    assert_operator s.bytesize, :<, ws.bytesize
    assert_equal s.size, ws.size
  end
end
