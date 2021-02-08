#!bin/bash
for each in $(find ./posts/imgs -type f)
do
    full_name=$(basename ${each})
    arr_name=($(echo ${full_name} | tr '-' ' '))
    img_path="../posts_imgs/$(echo ${arr_name[@]} | awk '{print $1"/"$2"/"$3}')"
    for i in $(seq 0 3)
    do
        unset arr_name[i]
    done
    img_name=$(echo ${arr_name[@]} | tr ' ' '-')
    target="${img_path}/${img_name}"
    echo ${target}    
done
