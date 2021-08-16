#!/bin/bash

source /etc/profile

if test "$1" = "run"; then
  port=8080
  if [ $2 ]; then
    port=$2
  fi
  bash src/format.sh
  bundle exec jekyll serve --watch --host=0.0.0.0 --port=$port
elif test "$1" = "runnew"; then
  port=8080
  if [ $2 ]; then
    port=$2
  fi
  rm -f src/md5sum.txt
  rm -rf _posts/*
  rm -rf posts_imgs/*
  bash src/format.sh
  bundle exec jekyll serve --watch --host=0.0.0.0 --port=$port
elif test "$1" = "build"; then
  bash src/format.sh
  bundle exec jekyll build --destination=dist
elif test "$1" = "deploy"; then
  echo "#####################$(date +"%Y-%m-%d-%H:%M:%S")###########################"
  bash src/format.sh
  # bundle exec jekyll build --destination=dist
  git pull && git add -A && git commit -m 'auto push' && git push
  echo -e "####################################################################\n\n"
elif test "$1" = "help"; then
  echo -e "help:"
  echo -e "\t1.run"
  echo -e "\t2.runnew"
  echo -e "\t3.build"
  echo -e "\t4.deploy"
else
  echo "error param"
fi
