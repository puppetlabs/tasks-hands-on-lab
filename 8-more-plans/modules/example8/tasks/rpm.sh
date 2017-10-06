#! /bin/bash

echo '{ "result": ['

first=yes

rpm -q --qf '%{NAME} %{VERSION} %{ARCH}\n' $PT_package |
    while read name version arch
    do
        if [[ "$first" = yes ]]
        then
            first=no
        else
            echo ","
        fi
        cat <<EOF
{
   "name": "$name",
   "version": "$version",
   "arch": "$arch" }
EOF
    done
echo "] }"
