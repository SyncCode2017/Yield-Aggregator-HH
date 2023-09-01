# Yield Aggregator Contract

This project allows a user to maximise his/her yield on Aave V3 and Compound V3 protocols.
It monitors the APY on both protocols and allow the user to move his//her WETH tokens to whichever 
protocol offers higher yield.

## Getting Started

To run this project locally, clone this repo. Then, run

```shell
yarn
```
in the project root in order to install all the dependencies.

Please see the .env.example file to set up your .env file appropriately.

To deploy the YieldAggregator.sol contract, the ethereum mainnet must be forked. We need to also pin the latest
block number to make the mainnet fork run faster. Run

```shell
yarn hardhat updateBlockNumber
```
to get the latest block number. Then, run the following command to deploy the contract locally.

```shell
yarn hardhat deploy
```

To run the unit tests in the test folder, run

```shell
yarn hardhat test
```

