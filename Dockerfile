FROM ruby:3.4.3-alpine3.21@sha256:c9956b1836f8c3f4fc4724e435baa037e55d32b302406742dfd5dcaadf7a4bb1

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