#!/bin/bash

source ./choose-builder.sh

$_BINARY build -t my-jekyll .

$_BINARY run --rm --volume="$PWD:/srv/jekyll:rw" --user root  my-jekyll:latest build -s /srv/jekyll/src -d /srv/jekyll/docs
