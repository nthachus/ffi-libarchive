# Ruby FFI binding to `libarchive` [![Build Status](https://travis-ci.org/nthachus/ffi_libarchive.svg?branch=master)](https://travis-ci.org/nthachus/ffi_libarchive)

This library provides Ruby FFI bindings to the well-known [libarchive library](https://www.libarchive.org/).

## Installation

Ensure that you have `libarchive` installed.

- On Debian/Ubuntu:

      $ apt install libarchive13

- On macOS with Homebrew:

      $ brew install libarchive

- On Windows with msys2:

      $ pacman -S mingw-w64-x86_64-libarchive

Add this line to your application's Gemfile:

```ruby
gem 'ffi_libarchive'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ffi_libarchive

## Usage

To extract an archive into the current directory:

```ruby
flags = Archive::EXTRACT_PERM
reader = Archive::Reader.open_filename('/path/to/archive.tgz')

reader.each_entry do |entry|
  reader.extract(entry, flags)
end
reader.close
```

To create a tar-gzipped archive:

```ruby
Archive.write_open_filename('my.tgz', Archive::COMPRESSION_GZIP, Archive::FORMAT_TAR_PAX_RESTRICTED) do |tar|
  content = File.read 'some_path'
  size = content.size

  tar.new_entry do |e|
    e.pathname = 'some_path'
    e.size = size
    e.filetype = Archive::Entry::FILE

    tar.write_header e
    tar.write_data content
  end
end
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rake` to run the tests.
You can also run `irb -r bundler/setup -r ffi_libarchive` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/nthachus/ffi_libarchive>.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Community Guidelines](https://www.chef.io/code-of-conduct/chef-contributor-covenant/) code of conduct.

## License

Licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

## Code of Conduct

Everyone interacting in the this project’s codebases, issue trackers,... is expected to follow the [Chef Community Code of Conduct](https://www.chef.io/code-of-conduct/).
