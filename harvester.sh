#!/usr/bin/bash

### Configuration

BINARY="" # Name of the binary, i.e. gaia
CHAIN_ID="" # Chain ID, i.e. cosmoshub-4
DENOM="" # Smallest token denomination, i.e. uatom
ACCOUNT="" # Name of the account/key
GAS_PRICES=0.0 # Gas prices in smallest token denomination, i.e. uatom
VALOPER="" # Valoper address of the validator to withdraw the staking rewards from
ADDR="" # Address to delegate the staking rewards to
NODE_ADDR="" # RPC address to make calls against, i.e. tcp://host:port
RESERVE=0 # Amount of tokens to keep in reserve
INTERVAL_SEC=0 # Interval in seconds to make withdrawals and delegations

### Routine

while true; do
    # Withdraw rewards from the validator account.
    echo "Fetching rewards for $VALOPER..."
    $BINARY tx distribution withdraw-rewards $VALOPER --from $ACCOUNT --chain-id $CHAIN_ID --commission --keyring-backend test -y --gas auto --gas-adjustment 1.5 --gas-prices $GAS_PRICES$DENOM -b block --node $NODE_ADDR
    sleep 10

    # Check the balance and calculate the amount to be delegated.
    echo "Checking balance..."
    total_balance=$($BINARY q bank balances $SD_ADDR --node $NODE_ADDR | grep amount: | grep -oP 'amount: "\K[^"]+')
    diff=$((total_balance-$RESERVE))

    # If there's nothing to delegate, wait for the next cycle.
    if [ $diff -lt 1 ]; then
       	echo "There's nothing to delegate, skipping cycle..."
        sleep $INTERVAL_SEC
       	continue
    fi

    echo "Total balance:   $total_balance$DENOM"
    echo "Reserved:        $RESERVE$DENOM"
    echo "To be delegated: $diff$DENOM"
    sleep 5

    # Self-delegate the withdrawn rewards to our validator.
    echo "Initiating self-delegation of $diff$DENOM..."
    $BINARY tx staking delegate $VALOPER $diff$DENOM --from $ACCOUNT --chain-id $CHAIN_ID --keyring-backend test -y --gas auto --gas-adjustment 1.5 --gas-prices $GAS_PRICES$DENOM -b block --node $NODE_ADDR
    sleep $INTERVAL_SEC
done