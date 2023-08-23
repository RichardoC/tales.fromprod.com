#!/bin/bash

rm -rf "$PWD/docs-tmp/"
mkdir "$PWD/docs-tmp/"

rm -rf "$PWD/docs/"
mkdir "$PWD/docs/"

source ./choose-builder.sh

_BINARY volume rm jekyll

_BINARY volume create jekyll
