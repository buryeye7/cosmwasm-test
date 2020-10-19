#!/bin/bash

TARGET="$HOME/workspace/cosmwasm-examples/escrow/target/wasm32-unknown-unknown/release/cw_escrow.wasm"
PW="12345678"

res=$(expect -c "
set timeout 3
spawn wasmcli tx wasm store $TARGET --from fred --gas-prices=0.025ucosm --gas=auto --gas-adjustment=1.2 -y
expect "passphrase:"
send \"$PW\\r\"
expect "passphrase:"
send \"$PW\\r\"
expect eof
")
res=$(echo $res | sed "s/[^A-Z,a-z,0-9, ,\,{,},\',\",:,[,]]//g")
echo $(echo $res | awk -F' ' '{print $NF}')
