ARG RUBY_VERSION=2.7.2
FROM ruby:$RUBY_VERSION-alpine

ENV SPOTLIGHT_ENGINE_PATH /spotlight/engine
ENV SPOTLIGHT_GEM /spotlight/engine

RUN apk --no-cache upgrade && \
  apk add --no-cache \
  bash \
  build-base \
  git \
  imagemagick \
  libxml2-dev \
  libxslt-dev \
  nodejs-current \
  postgresql-dev \
  sqlite-dev \
  tzdata \
  yarn

RUN addgroup -S --gid 101 spotlight && \
  adduser -S -G spotlight -u 1001 -s /bin/sh -h /spotlight spotlight
USER spotlight

RUN gem update bundler
RUN gem install --no-document rails -v '< 6.1'

RUN mkdir -p /spotlight/engine
COPY --chown=1001:101 . /spotlight/engine
RUN cd /spotlight/engine && bundle install --jobs "$(nproc)"

RUN mkdir -p /spotlight/app
WORKDIR /spotlight/app
RUN rails new . --force --template=../engine/template.rb

RUN DB_ADAPTER=nulldb DATABASE_URL='postgresql://fake' bundle exec rake assets:precompile

ENTRYPOINT ["/spotlight/engine/bin/docker-entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:3000"]
