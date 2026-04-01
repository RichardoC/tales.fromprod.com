#!/bin/bash

source ./choose-builder.sh

$_BINARY build -t my-jekyll:updates . -f Dockerfile-updates

$_BINARY run -p 4000:4000 --rm --user root --entrypoint bundle --volume="$(pwd):/srv/jekyll:rw" my-jekyll:updates update --all
