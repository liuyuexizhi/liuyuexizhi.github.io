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
  bundle exec jekyll build --destination=dist
  # ~/bin/blog-deploy-linux -src=./dist
  git pull && git add -A && git commit -m 'auto push' && git push
else
  echo "error param"
fi
