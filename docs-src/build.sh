#!/bin/sh

cd "$(dirname "$0")"
NO_MKDOCS_2_WARNING=1 mkdocs gh-deploy --force
