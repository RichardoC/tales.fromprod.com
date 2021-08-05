#!/bin/bash

source JEKYLL_VERSION.sh

docker run --rm --volume="$PWD:/srv/jekyll" --volume="$PWD/.gemdata:/usr/local/bundle" -it jekyll/jekyll:$JEKYLL_VERSION jekyll build -s /srv/jekyll/src -d /srv/jekyll/docs --incremental
