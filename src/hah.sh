#!bin/bash

md5_file="md5sum.txt"

function md5_clear()
{
    # 检查记录的文件是否被删除
    [ -f ${md5_file} ] || touch ${md5_file}
    for ff in $(awk '{print $2}' ${md5_file})
    do
        if [[ -f ${ff} ]]
        then
            continue
        else
            fname=$(basename ${ff})
            suffix=${fname##*.}
            grep -F ${fname} ${md5_file} | awk '{print $1}' | xargs -i sed -i "/{}/d" ${md5_file}
            if [[ ${suffix} == 'md' ]]
            then
                thisfile=$(echo ${fname} | sed "s@-\[.*\]@@")
                topath="../_posts/${thisfile}"
                rm -fv ${topath}
            else
                fullname=$(basename ${each})
                f_date=$(echo ${fullname} | awk -F '_' '{print $1}')
                img_path="../posts_imgs/$(echo ${f_date}  | awk -F '-' '{print $1"/"$2"/"$3}')"
                img_name=$(echo ${fullname} | awk -F '_' '{print $NF}')
                target="${img_path}/${img_name}"
                rm -fv ${target}
            fi
        fi
    done
}


