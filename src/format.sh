#!/bin/bash


rm -rf ../_posts/*

for post in $(find ./posts -type f -name "*.md")
do
    post_file=$(basename ${post})
    temp_str=${post_file:11}
    this_title=${temp_str%.*}
    sed -e "4 a ## 目录\n+ this is a toc line\n{:toc}\n" \
        -e "4 a {% raw %}\n" \
        -e "$ a {% endraw %}" \
        -e "1 a title: ${this_title}" \
        -e "s/<\(.*\)>/\\\<\1\\\>/" ${post} > ../_posts/${post_file}
done
