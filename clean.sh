#!/bin/bash

rm -rf "$PWD/docs-tmp/"
mkdir "$PWD/docs-tmp/"

rm -rf "$PWD/docs/"
mkdir "$PWD/docs/"


export _BINARY="docker"

if [ -x "$(command -v lima)" ]; then
  echo 'lima is installed so using it instead' >&2
  _BINARY="lima nerdctl "
elif [ -x "$(command -v nerdctl)" ]; then
  echo 'nerdctl is installed so using it instead' >&2
  _BINARY="nerdctl "
fi

nerdctl volume rm jekyll

nerdctl volume create jekyll