## Decentralized Budget Management System
This project aims to implement a decentralized budget management system where the smart contract governs fund allocations to various departments. Departments can request and receive funds based on their allocated budgets, ensuring efficient financial management. The system leverages smart contract technology to provide transparency and security in budget allocations, preventing unauthorized access and re-entrancy attacks.

## Installation
**To get started install both Git and Foundry**

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git): After installation make sure to run *****git --version***** to confirm installation if you see a response like *****git version 2.34.1*****
then it was successful.

- [Foundry](https://getfoundry.sh/): After installation run *****forge --version***** if you see a response like *****forge 0.2.0 (8549aad 2024-08-19T00:21:29.325298874Z)***** then it was successful.

## Clone the repository
```shell
git clone https://github.com/Joewizy/Decentralized-Budget-System
cd Joewizy/Decentralized-Budget-System
forge build
```
## Test

```shell
$ forge test
```
### Test Coverage
```shell
$ forge coverage
```
To view detailed test coverage reports for your contracts
## Usage
### Start a local node
```shell
$ make anvil
```
### Deploy
By default, your local node will be used here. For it to deploy, anvil must be running in a separate terminal.
```shell
$ make deploy
```

### Deploy to Sepolia Testnet
By default, your local node will be used here. For it to deploy, it must be running in a separate terminal. All this varaibles should be added to your **.env** file. 
1. Setup your environment variables **PRIVATE_KEY** , **ETHERSCAN_API**_KEY and **SEPOLIA_RPC_URL**.
- **PRIVATE_KEY**: Import your metamask private key. It is recommended you use a wallet with no funds or a burner wallet. Learn how to export private key [HERE](https://support.metamask.io/managing-my-wallet/secret-recovery-phrase-and-private-keys/how-to-export-an-accounts-private-key/)
- **SEPOLIA_RPC_URL**: This is URL of the sepolia testnet node you're working with. You can get setup with one for free from [Alchemy](https://www.alchemy.com/?a=673c802981)
- **ETHERSCAN_API_KEY**: for verification of your contract on [Etherscan](https://etherscan.io/). Learn how to get one [HERE](https://docs.etherscan.io/getting-started/viewing-api-usage-statistics)
2. Get ETH testnet tokens by heading over to [faucets.chain.link](https://faucets.chain.link/) and claim some testnet ETH. 
3. Deploy
```shell
source .env
make deploy ARGS="--network sepolia"
```

### Scripts
We can communicate with the contract directly with the ***cast*** command in place of scripts.
For example
* Get the total budget of the System
```shell
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "getTotalBudget()(uint256)" --rpc-url $LOCAL_CHAIN_RPC
```
* Allocate the funds to an address(department)
```shell
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "allocateBudget(address,uint256)" 0x091EA0838eBD5b7ddA2F2A641B068d6D59639b98 1000000000000000000 --rpc-url $LOCAL_CHAIN_RPC --private-key $DEFAULT_ANVIL_KEY
```
* To allocate funds if deployed on Sepolia testnet
```shell
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "allocateBudget(address,uint256)" 0x091EA0838eBD5b7ddA2F2A641B068d6D59639b98 1000000000000000000 --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```
### Gas Snapshots
You can estimate how much gas things cost by running:

```shell
$ forge snapshot
```
And you'll see an output file called **.gas-snapshot**

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

