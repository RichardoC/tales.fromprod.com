#!/bin/bash

source ./choose-builder.sh

$_BINARY run -p 4000:4000 --rm --entrypoint bundle --volume="$(pwd):/srv/jekyll:rw" -it jekyll update --all
