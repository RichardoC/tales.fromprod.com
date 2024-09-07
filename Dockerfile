FROM ruby:3.3.5-alpine3.20@sha256:e401afe8db419ecb62a872e4f6f2d056bcf26d22d6a79b82439a2f84a4596331

# Based on https://github.com/rockstorm101/jekyll-docker/blob/master/Dockerfile

ENV SETUPDIR=/setup
WORKDIR ${SETUPDIR}
ARG GEMFILE_DIR=.
COPY $GEMFILE_DIR/Gemfile* $GEMFILE_DIR/packages* .

# Install build dependencies
RUN set -eux; \
    apk add --no-cache --virtual build-deps \
    build-base \
    zlib-dev make \
    ;

# Install Bundler
RUN set -eux; gem install bundler

# Install extra packages if needed
RUN set -eux; \
    if [ -e packages ]; then \
    cat packages | apk add --no-cache --virtual extra-pkgs; \
    fi

# Install gems from `Gemfile` via Bundler
RUN set -eux; bundler install

# Remove build dependencies
RUN set -eux; apk del --no-cache build-deps

# Clean up
WORKDIR /srv/jekyll
# RUN set -eux; \
#     rm -rf \
#         ${SETUPDIR} \
#         /usr/gem/cache \
#         /root/.bundle/cache \
#     ;

EXPOSE 4000
ENTRYPOINT ["bundler", "exec", "jekyll"]
CMD ["--version"]