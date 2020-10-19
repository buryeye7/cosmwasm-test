#!/bin/bash

TARGET="$HOME/workspace/cosmwasm-examples/escrow/target/wasm32-unknown-unknown/release/cw_escrow.wasm"
PW="12345678"

CODE_LIST=$(wasmcli query wasm list-code)

echo "previous code list" 
if [[ "$CODE_LIST" == *"null"* ]];then
    echo $CODE_LIST            
else
    echo $CODE_LIST | jq .
fi

function store() {
    res=$(expect -c "
    set timeout 3
    spawn wasmcli tx wasm store $TARGET --from $1 --gas-prices=0.025ucosm --gas=auto --gas-adjustment=1.2 -y
    expect "passphrase:"
    send \"$PW\\r\"
    expect "passphrase:"
    send \"$PW\\r\"
    expect eof
    ")
    res=$(echo $res | sed "s/[^A-Z,a-z,0-9, ,\,{,},\',\",:,[,]]//g")
    echo $(echo $res | awk -F' ' '{print $NF}')
}

echo "store fred"
RES=$(store fred)
echo $RES | jq .
sleep 10

echo "next code list" 
CODE_LIST=$(wasmcli query wasm list-code)
echo $CODE_LIST | jq .

CODE_ID=$(echo $CODE_LIST | jq .[0].id)
CONTRACTS=$(wasmcli query wasm list-contract-by-code $CODE_ID)
echo "contracts" 
echo $CONTRACTS | jq .

wasmcli query wasm code $CODE_ID download.wasm
diff $TARGET download.wasm
