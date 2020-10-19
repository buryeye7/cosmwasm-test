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

function instantiate() {
    code_id=$1
    message=$(echo $2 | sed "s/\n//g" | sed "s/ //g")
    echo "message" $message
    expect -c "
    set timeout 3
    spawn wasmcli tx wasm instantiate $code_id {${message}} --from fred --amount=50000ucosm  --label escrow_1 --gas-prices=0.025ucosm --gas=auto --gas-adjustment=1.2 -y
    expect "passphrase:"
    send \"$PW\\r\"
    expect "passphrase:"
    send \"$PW\\r\"
    expect eof
    "
}

fred=$(show_key fred)
bob=$(show_key bob)

echo "fred" $fred
echo "bob" $bob

# instantiate contract and verify
CODE_ID=$(wasmcli query wasm list-code | jq .[0].id)
echo "code id" $CODE_ID
INIT=$(jq -n --arg fred $fred --arg bob $bob '{"arbiter":$fred,"recipient":$bob}')
echo "instantiating message format" $INIT

instantiate $CODE_ID "$INIT"
sleep 10
# check the contract state (and account balance)
wasmcli query wasm list-contract-by-code $CODE_ID

CONTRACT=$(wasmcli query wasm list-contract-by-code $CODE_ID | jq -r '.[0].address')
echo "contract_id" $CONTRACT

# we should see this contract with 50000ushell

CONTRACT_CONTENT=$(wasmcli query wasm contract $CONTRACT)
ACCOUNT=$(wasmcli query account $CONTRACT)
STATE=$(wasmcli query wasm contract-state all $CONTRACT)

echo "CONTRACT" 
echo $CONTRACT_CONTENT | jq .
echo "ACCOUNT" 
echo $ACCOUNT | jq .
echo "STATE" 
echo $STATE | jq .

# note that we prefix the key "config" with two bytes indicating it's length
# echo -n config | xxd -ps
# gives 636f6e666967
# thus we have a key 0006636f6e666967

# you can also query one key directly
echo "contract-state call raw"
wasmcli query wasm contract-state raw $CONTRACT 0006636f6e666967 --hex | jq .

# Note that keys are hex encoded, and val is base64 encoded.
# To view the returned data (assuming it is ascii), try something like:
# (Note that in many cases the binary data returned is non in ascii format, thus the encoding)
echo "contract-state | jq .[0].key | xxd -r -ps"
wasmcli query wasm contract-state all $CONTRACT | jq -r '.[0].key' | xxd -r -ps
echo "contract-state | jq .[0].value | bae64 -d | jq ."
wasmcli query wasm contract-state all $CONTRACT | jq -r '.[0].val' | base64 -d | jq .

# or try a "smart query", executing against the contract
echo "smart call"
wasmcli query wasm contract-state smart $CONTRACT '{}'
# (since we didn't implement any valid QueryMsg, we just get a parse error back)
