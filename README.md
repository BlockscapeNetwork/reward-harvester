# Staking Reward Harvester

Script for periodically withdrawing staking rewards and delegating them to a validator. Works with Cosmos SDK-based chains.

> :warning: Due to bash only supporting 64-bit integers, this script won't work well with tokens that have many decimals.
> To be sure, please don't use this script for tokens with more than 16 decimals.

## Prerequisites

* Full or validator node with open RPC port
* Account/Key (must be in keyring-backend `test`) used to withdraw and stake rewards

## Usage

First, make sure you import your account/key.

```bash
$ simd keys add <NAME> --recover --keyring-backend test # keyring-backend test is needed, as it doesn't ask for a passphrase when signing txs
# Enter your mnemonic once prompted
```

Next, open `harvester.sh` and modify the values in the configuration part on top to your needs.

Finally, make sure you can execute the script with `chmod +x harvester.sh` and start it via `./harvester`.
