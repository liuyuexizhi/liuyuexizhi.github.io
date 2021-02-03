#!/bin/bash

source /etc/profile

if test "$1" = "run"; then
  port=8080
  if [ $2 ]; then
    port=$2
  fi
  bundle exec jekyll serve --watch --host=0.0.0.0 --port=$port
elif test "$1" = "build"; then
  bundle exec jekyll build --destination=dist
elif test "$1" = "deploy"; then
  echo "#####################$(date +"%Y-%m-%d-%H:%M:%S")###########################"
  bundle exec jekyll build --destination=dist
  bash src/format.sh
  git pull && git add -A && git commit -m 'auto push' && git push
  echo -e "####################################################################\n\n"
else
  echo "error param"
fi
