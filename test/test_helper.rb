# frozen_string_literal: true

begin
  require 'simplecov'
rescue LoadError # rubocop:disable all
else
  SimpleCov.start
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ffi_libarchive'

require 'test/unit'

module TestHelper
  # @param [String] str
  # @return [String]
  def self.bin_string(str)
    str.respond_to?(:b) ? str.b : str.dup.force_encoding(Encoding::BINARY)
  end

  CONTENT_SPEC = [
    ['test/', :directory, 0o755, nil],
    ['test/b/', :directory, 0o755, nil],
    ['test/b/c/', :directory, 0o755, nil],
    [
      'test/b/c/c.dat', :file, 0o600,
      bin_string(
        "\266\262\v_\266\243\305\3601\204\277\351\354\265\003\036\036\365f\377\210\205\032\222\346\370b\360u\032Y\301"
      )
    ],
    ['test/b/c/d/', :directory, 0o711, nil],
    ['test/b/c/d/d.dat', :symbolic_link, 0o777, '../c.dat'],
    [
      'test/b/b.dat', :file, 0o640,
      bin_string("s&\245\354(M\331=\270\000!s\355\240\252\355'N\304\343\bY\317\t\274\210\3128\321\347\234!")
    ],
    [
      'test/a.dat', :file, 0o777,
      bin_string("\021\216\231Y\354\236\271\372\336\213\224R\211{D{\277\262\304\211xu\330\\\275@~\035\vSRM")
    ]
  ].freeze

  # @param [String] filename
  # @return [String]
  def self.fixture_path(*filename)
    File.join(File.expand_path('../data', __FILE__), *filename)
  end

  private

  # @return [String]
  def fixture_path(*args)
    TestHelper.fixture_path(*args)
  end
end
