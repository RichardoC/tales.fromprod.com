#!/bin/bash

source JEKYLL_VERSION.sh

source ./choose-builder.sh

$_BINARY run --rm --volume="$PWD:/srv/jekyll:rw" --user root --volume="jekyll:/usr/local/bundle" -it jekyll/jekyll:$JEKYLL_VERSION jekyll build -s /srv/jekyll/src -d /srv/jekyll/docs
