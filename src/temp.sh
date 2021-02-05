#!bin/bash

for each in $(awk '{print $2}' md5sum.txt)
do
    echo $each
done
