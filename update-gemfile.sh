#!/bin/bash

source ./choose-builder.sh

$_BINARY run -p 4000:4000 --rm  --user root -it --entrypoint bundle --volume="$(pwd):/srv/jekyll:rw" -it jekyll update --all
