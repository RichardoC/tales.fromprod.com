#!/bin/bash

source ./choose-builder.sh

$_BINARY run -p 4000:4000 --rm --volume="$(pwd):/srv/jekyll:rw" -it jekyll serve -s /srv/jekyll/src -d /srv/jekyll/docs-tmp --watch --incremental -H 0.0.0.0
