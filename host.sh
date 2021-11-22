#!/bin/bash

source JEKYLL_VERSION.sh

./clean.sh

export _BINARY="docker"

if [ -x "$(command -v lima)" ]; then
  echo 'lima is installed so using it instead' >&2
  _BINARY="lima nerdctl "
elif [ -x "$(command -v nerdctl)" ]; then
  echo 'nerdctl is installed so using it instead' >&2
  _BINARY="nerdctl "
fi


$_BINARY run --rm --publish 127.0.0.1:4000:4000 --volume="$(pwd):/srv/jekyll:rw" --volume="$(pwd)/.gemdata:/usr/local/bundle:rw" -it jekyll/jekyll:$JEKYLL_VERSION jekyll serve -s /srv/jekyll/src -d /srv/jekyll/docs-tmp --watch --incremental
