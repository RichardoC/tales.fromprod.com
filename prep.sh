#!/bin/bash

source JEKYLL_VERSION.sh

docker run --rm -it --volume="$PWD:/srv/jekyll" --volume="$PWD/.gemdata:/usr/local/bundle" -it jekyll/jekyll:$JEKYLL_VERSION bash