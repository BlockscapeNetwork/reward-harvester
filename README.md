# Staking Reward Harvester

Script for periodically withdrawing staking rewards and delegating them to a validator. Works with Cosmos SDK-based chains.

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
