#!/bin/bash

source JEKYLL_VERSION.sh

source ./choose-builder.sh

$_BINARY run -p 4000:4000 --rm --volume="$(pwd):/srv/jekyll:rw" --volume="jekyll:/usr/local/bundle" -it jekyll/jekyll:$JEKYLL_VERSION jekyll serve -s /srv/jekyll/src -d /srv/jekyll/docs-tmp --watch --incremental
