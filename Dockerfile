FROM ruby:3.3.6-alpine3.20@sha256:008baee4c694e2ac33d625c66304dc4323ab9f284d483ea6d0c4c08d2887ce3d

# Based on https://github.com/rockstorm101/jekyll-docker/blob/master/Dockerfile

ENV SETUPDIR=/setup
WORKDIR ${SETUPDIR}
ARG GEMFILE_DIR=.
COPY $GEMFILE_DIR/Gemfile* ./
# COPY $GEMFILE_DIR/packages/* ./

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