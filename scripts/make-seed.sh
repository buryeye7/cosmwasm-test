#!/bin/bash

# default home is ~/.wasmd
# if you want to setup multiple apps on your local make sure to change this value

ps -ef | grep wasmd > /tmp/wasmd.txt

while read line
do
    if [[ "$line" == *"autl"* ]];then
        continue   
    fi 
    process=$(echo $line | awk -F' ' '{print $2}')
    kill -9 $process
done < /tmp/wasmd.txt

rm -rf "$HOME/.wasmd"
rm -rf "$HOME/.wasmcli"

PW="12345678"
APP_HOME="$HOME/.wasmd"
CLI_HOME="$HOME/.wasmcli"

function add_key_first() {
    expect -c "
    set timeout 3 
    spawn wasmcli keys add $1 
    expect "passphrase:"
    send \"$PW\\r\"
    expect "passphrase:"
    send \"$PW\\r\"
    expect eof
    "
}

function add_key() {
    expect -c "
    set timeout 3
    spawn wasmcli keys add $1
    expect "passphrase:"
    send \"$PW\\r\"
    expect eof
    "
}

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

function gentx() {
    expect -c "
    set timeout 3
    spawn wasmd gentx --name $1 
    expect "passphrase:"
    send \"$PW\\r\"
    expect "passphrase:"
    send \"$PW\\r\"
    expect "passphrase:"
    send \"$PW\\r\"
    expect eof
    "
}

# initialize wasmd configuration files
wasmd init localnet --chain-id localnet 

# add minimum gas prices config to app configuration file
sed -i -r 's/minimum-gas-prices = ""/minimum-gas-prices = "0.025ucosm"/' ${APP_HOME}/config/app.toml

# setup client
wasmcli config chain-id localnet 
wasmcli config trust-node true 
wasmcli config node http://localhost:26657 
wasmcli config output json 

add_key_first fred
add_key bob
add_key thief

rm ./accounts.txt

fred=$(show_key fred)
thief=$(show_key thief)
bob=$(show_key bob)

echo "fred" $fred >> ./logs/accounts.txt
echo "thief" $thief >> ./logs/accounts.txt
echo "bob" $bob >> ./logs/accounts.txt

wasmd add-genesis-account $fred 10000000000ucosm,10000000000stake
wasmd add-genesis-account $thief 10000000000ucosm,10000000000stake 

gentx fred

wasmd collect-gentxs 
wasmd validate-genesis

# run the node
wasmd start 
