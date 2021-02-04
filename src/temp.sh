#/bin/bash

for each in $(find ./posts/imgs -type f)
do
    full_name=$(basename ${each})
    temp_str=${full_name:11}
    img=${temp_str#*-}
    img_date=${full_name:0:10}
    img_path="../imgs/$(echo ${img_date} | tr '-' '/')"
    echo "=====Format:: ${full_name} ====="
    [[ -d "${img_path}" ]] || mkdir -p ${img_path} 
    cp -f "${img}" "${img_path}/${img}"
done

