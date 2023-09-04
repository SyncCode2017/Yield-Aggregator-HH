# IYieldAggregator
[Git Source](https://github.com/SyncCode2017/yield-aggregator-hh/blob/01148571bb2766461391b15c703f4fd7ab15471a/contracts/interfaces/IYieldAggregator.sol)


## Functions
### depositWETH

Allow the owner to deposit to Aave and Compound

*only accepts WETH token*


```solidity
function depositWETH(uint256 _amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|in wei to be deposited|


### withdrawWETH

Allows the owner to withraw his asset from Aave or Compound


```solidity
function withdrawWETH() external;
```

### rebalanceWETH

Allows the caller to move the asset the protocol with higher apy


```solidity
function rebalanceWETH() external;
```

### getAaveCurrentWETHAPY

*Returns Aave APY*


```solidity
function getAaveCurrentWETHAPY() external view returns (uint256);
```

### getCompoundCurrentWETHAPY

*Returns Compound APY*


```solidity
function getCompoundCurrentWETHAPY() external view returns (uint256);
```

### getCompoundWETHCurrentBalance

*Returns current contract balance in Compound*


```solidity
function getCompoundWETHCurrentBalance() external view returns (uint256);
```

### getAaveWETHCurrentBalance

*Returns current contract balance in Aave*


```solidity
function getAaveWETHCurrentBalance() external view returns (uint256);
```

## Events
### FundsWithdrawn
*Emitted when funds are withdrawn by the user*


```solidity
event FundsWithdrawn(address _owner, uint256 _amount);
```

### FundsDepositedToAave
*Emitted when funds are deposited*


```solidity
event FundsDepositedToAave(uint256 _amount);
```

### FundsWithdrawnFromAave
*Emitted when funds are withdrawn from Aave*


```solidity
event FundsWithdrawnFromAave(uint256 _amount);
```

### FundsDepositedToCompound
*Emitted when funds are deposited to Compound*


```solidity
event FundsDepositedToCompound(uint256 _amount);
```

### FundsWithdrawnFromCompound
*Emitted when funds are withdrawn from Compound*


```solidity
event FundsWithdrawnFromCompound(uint256 _amount);
```

### FundsMovedFromAaveToCompound
*Emitted when funds are rebalanced from Aave to Compound*


```solidity
event FundsMovedFromAaveToCompound(uint256 _amount);
```

### FundsMovedFromCompoundToAave
*Emitted when funds are rebalanced from Compound to Aave*


```solidity
event FundsMovedFromCompoundToAave(uint256 _amount);
```

## Errors
### ApproveRightAmount

```solidity
error ApproveRightAmount();
```

### InsufficientBalance

```solidity
error InsufficientBalance();
```

### NoAaveRewardsClaimed

```solidity
error NoAaveRewardsClaimed();
```

### DepositToAaveFailed

```solidity
error DepositToAaveFailed();
```

### AaveWithdrawalFailed

```solidity
error AaveWithdrawalFailed();
```

### DepositToCompoundFailed

```solidity
error DepositToCompoundFailed();
```

### CompoundWithdawalFailed

```solidity
error CompoundWithdawalFailed();
```

### ClaimRewardsFromCompoundFailed

```solidity
error ClaimRewardsFromCompoundFailed();
```

### ClaimAaveRewardsFailed

```solidity
error ClaimAaveRewardsFailed();
```

### NoRebalanceRequired

```solidity
error NoRebalanceRequired();
```

