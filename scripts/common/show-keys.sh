#!/bin/bash

PW="12345678"

res=$(expect -c "
set timeout 3
spawn wasmcli keys show -a fred
expect "passphrase:"
send \"$PW\\r\"
expect eof
" | sed "s/[^A-Z,a-z,0-9, ,:,\,,\-]//g")
echo $(echo $res | awk -F' ' '{print $NF}')
