#!/bin/bash

PW="12345678"

function show_key() {
    res=$(expect -c "
    set timeout 3
    spawn wasmcli keys show -a $1
    expect "passphrase:"
    send \"$PW\\r\"
    expect eof
    " | sed "s/[^A-Z,a-z,0-9, ,:,\,,\-]//g")
    echo $(echo $res | awk -F' ' '{print $NF}')
}

function execute_contract() {
    contract=$1
    approve="$2"
    sender=$3
    expect -c "
    set timeout 3
    spawn wasmcli tx wasm execute $contract {$approve} --from $sender --gas-prices="0.025ucosm" --gas="auto" --gas-adjustment="1.2" -y
    expect "passphrase:"
    send \"$PW\\r\"
    expect "passphrase:"
    send \"$PW\\r\"
    expect eof
    "
}

CODE_ID=$(wasmcli query wasm list-code | jq .[0].id)
CONTRACT=$(wasmcli query wasm list-contract-by-code $CODE_ID | jq -r '.[0].address')
echo "contract" $CONTRACT >> ./logs/accounts.txt

APPROVE='{"approve":{"quantity":[{"amount":"50000","denom":"ucosm"}]}}'

execute_contract $CONTRACT "$APPROVE" "thief"
sleep 10
bob=$(show_key bob)
wasmcli query account $bob

execute_contract $CONTRACT "$APPROVE" "fred"
sleep 10
bob=$(show_key bob)
wasmcli query account $bob

wasmcli query account $CONTRACT
