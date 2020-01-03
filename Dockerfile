# docker build -t ffi_libarchive --rm --build-arg ruby_version=1.9.3 .
ARG ruby_type=ruby
ARG ruby_version=latest
FROM $ruby_type:$ruby_version

# Install runtime dependencies
RUN apt-get update -qq \
 && apt-get install -qy --no-install-recommends libarchive13 \
 && rm -rf /tmp/* /var/lib/apt/lists/* \
 && if [ "1.14" = "`bundle -v | sed 's/^[^0-9]*/1.14\n/' | sort -V | tail -n1`" ]; then gem install bundler -v 1.16.1; fi

WORKDIR /usr/src/app
ENV LANG C.UTF-8

# Install dependencies
COPY Gemfile *.gemspec ./
RUN bundle install --path vendor/bundle --without coverage \
 && rm -rf ~/.bundle ~/.gem

COPY . .

CMD ["bundle", "exec", "rake"]
