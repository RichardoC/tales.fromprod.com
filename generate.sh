#!/bin/bash

source ./choose-builder.sh

$_BINARY build -t jekyll .

$_BINARY run --rm --volume="$PWD:/srv/jekyll:rw" --user root  jekyll:latest build -s /srv/jekyll/src -d /srv/jekyll/docs
