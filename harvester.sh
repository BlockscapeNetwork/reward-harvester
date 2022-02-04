#!/bin/bash

### Configuration

BINARY="" # Name of the binary, e.g. gaiad
CHAIN_ID="" # Chain ID, e.g. cosmoshub-4
DENOM="" # Smallest token denomination, e.g. uatom
ACCOUNT="" # Name of the account/key, e.g. validator
GAS_PRICES=0.0 # Gas prices in smallest token denomination
VALOPER="" # Valoper address of the validator to withdraw the staking rewards from, i.e. cosmosvaloper1...
ADDR="" # Address to delegate the staking rewards to, i.e. cosmos1...
NODE_ADDR="" # RPC address to make calls against, i.e. tcp://host:port
WITHDRAW_THRESHOLD=0 # Minimum amount of tokens that need to have accumulated from rewards in order for them to be withdrawn
RESERVE=0 # Amount of tokens to keep in reserve
MIN_DELEGATION=0 # Minimum amount of tokens to delegate
INTERVAL_SEC=0 # Interval in seconds to make withdrawals and delegations

### Routine

while true; do
    echo "Checking delegation rewards..."
    rewards=$($BINARY q distribution rewards $ADDR $VALOPER --node $NODE_ADDR --output json | jq '.rewards[] | select(.denom == "'$DENOM'") | .amount' | sed 's/\"//g' | sed 's/\..*//g')
    echo $rewards$DENOM

    echo "Checking validator commission..."
    commission=$($BINARY q distribution commission $VALOPER --node $NODE_ADDR --output json | jq '.commission[] | select(.denom == "'$DENOM'") | .amount' | sed 's/\"//g' | sed 's/\..*//g')
    echo $commission$DENOM

    # Fetch rewards & commission if they exceed the specified withdraw threshold.
    if [ ! $((rewards+commission)) -lt $WITHDRAW_THRESHOLD ]; then
        echo "Withdrawing delegation rewards and validator commission for $VALOPER..."
        $BINARY tx distribution withdraw-rewards $VALOPER --from $ACCOUNT --chain-id $CHAIN_ID --commission --keyring-backend test -y --gas auto --gas-adjustment 1.5 --gas-prices $GAS_PRICES$DENOM -b block --node $NODE_ADDR
        sleep 30
    else
        echo "Withdraw threshold not reached yet ($((rewards+commission))$DENOM < $WITHDRAW_THRESHOLD$DENOM), skipping cycle..."
        sleep $INTERVAL_SEC
        continue
    fi

    # Check the new balance and calculate the delegation amount.
    echo "Checking balance..."
    total_balance=$($BINARY q bank balances $ADDR --node $NODE_ADDR --output json | jq '.balances[] | select(.denom == "'$DENOM'") | .amount' | sed 's/\"//g')
    diff=$((total_balance-RESERVE))

    # If there's nothing to delegate, wait for the next cycle.
    if [ $diff -lt 1 ]; then
       	echo "There's nothing to delegate, skipping cycle..."
        sleep $INTERVAL_SEC
       	continue
    fi

    # Check if the diff is greater than or equal to the minimum delegation amount.
    if [ $diff -lt $MIN_DELEGATION ]; then
        echo "Minimum delegation amount not reached yet ($diff$DENOM < $MIN_DELEGATION$DENOM), skipping cycle..."
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