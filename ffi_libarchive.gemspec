# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name          = 'ffi_libarchive'
  s.version       = '1.0.1'
  s.authors       = ['John Bellone', 'Jamie Winsor', 'Frank Fischer', 'Thach Nguyen']
  s.email         = %w[jbellone@bloomberg.net jamie@vialstudios.com frank-fischer@shadow-soft.de nthachus@gmail.com]

  s.summary       = 'A Ruby FFI binding to libarchive.'
  s.description   =
    'This library provides Ruby FFI bindings to the well-known [libarchive library](https://www.libarchive.org/).'
  s.homepage      = 'https://github.com/nthachus/ffi_libarchive'
  s.license       = 'Apache-2.0'

  # Specify which files should be added to the gem when it is released.
  s.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    %w[LICENSE README.md] + Dir['lib/**/*'].reject { |f| File.directory? f }
  end

  s.require_paths = ['lib']
  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency 'ffi', '~> 1.0'

  s.add_development_dependency 'bundler', '>= 1.14'
  s.add_development_dependency 'rake', '>= 10.0'
  s.add_development_dependency 'rubocop', '~> 0.41'
  s.add_development_dependency 'test-unit', '~> 3.2'
end
