#!/bin/bash

source JEKYLL_VERSION.sh

export _BINARY="docker"

if [ -x "$(command -v lima)" ]; then
  echo 'lima is installed so using it instead' >&2
  _BINARY="lima nerdctl "
elif [ -x "$(command -v nerdctl)" ]; then
  echo 'nerdctl is installed so using it instead' >&2
  _BINARY="nerdctl "
fi


$_BINARY run -p 4000:4000 --rm --volume="$(pwd):/srv/jekyll:rw" --volume="jekyll:/usr/local/bundle" -it jekyll/jekyll:$JEKYLL_VERSION bundle update
