#!/bin/bash

source JEKYLL_VERSION.sh

docker run --rm --publish 127.0.0.1:4000:4000 --volume="$PWD:/srv/jekyll" --volume="$PWD/.gemdata:/usr/local/bundle" -it jekyll/jekyll:$JEKYLL_VERSION jekyll serve -s /srv/jekyll/jekyll -d /srv/jekyll/docs --incremental --watch
