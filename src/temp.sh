#!bin/bash

for each in $(find ./posts -type f -name '*.md')
do
    fullname=$(basename ${each})
    tag=$(echo ${fullname} | grep -Eo '\[.*\]')
    thisfile=$(echo ${fullname} | sed "s@-\[.*\]@@")
    topath="../_posts/${thisfile}"
    echo ${topath}
done
