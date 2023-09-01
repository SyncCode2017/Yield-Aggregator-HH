# YieldAggregator
[Git Source](https://github.com/SyncCode2017/yield-aggregator-hh/blob/9547b64ff0dde35cf66a54081393a0499b5c1eda/contracts/YieldAggregator.sol)

**Inherits:**
[IYieldAggregator](/contracts/interfaces/IYieldAggregator.sol/interface.IYieldAggregator.md), ReentrancyGuard, Ownable

**Author:**
Abolaji

*It monitors APY of both Aave and COMPOUND and deposit the user's WETH tokens into the protocol
with higher APY.*


## State Variables
### WETH_ADDRESS

```solidity
address public immutable WETH_ADDRESS;
```


### DAYS_PER_YEAR

```solidity
uint48 public constant DAYS_PER_YEAR = 365;
```


### SECONDS_PER_DAY

```solidity
uint48 public constant SECONDS_PER_DAY = 60 * 60 * 24;
```


### compAddress

```solidity
address public immutable compAddress;
```


### SECONDS_PER_YEAR

```solidity
uint96 public constant SECONDS_PER_YEAR = SECONDS_PER_DAY * DAYS_PER_YEAR;
```


### compRewardAddress

```solidity
address public immutable compRewardAddress;
```


### COMPOUND

```solidity
Comet public immutable COMPOUND;
```


### wethCompPriceFeed

```solidity
address public wethCompPriceFeed;
```


### RAY

```solidity
uint96 public constant RAY = 10 ** 27;
```


### BASE_MANTISSA

```solidity
uint256 public BASE_MANTISSA;
```


### BASE_INDEX_SCALE

```solidity
uint256 public BASE_INDEX_SCALE;
```


### MAX_UINT

```solidity
uint256 public constant MAX_UINT = type(uint256).max;
```


### aaveRewardsContract

```solidity
IRewardsController public aaveRewardsContract;
```


### LENDING_POOL_ADDRESSES_PROVIDER

```solidity
IPoolAddressesProvider public immutable LENDING_POOL_ADDRESSES_PROVIDER;
```


### aaveDataProvider

```solidity
IPoolDataProvider public immutable aaveDataProvider;
```


### aaveLendingPool

```solidity
IPool public aaveLendingPool;
```


## Functions
### constructor

Initialises the contract


```solidity
constructor(
    address _wethAddress,
    address _cometAddress,
    address _cometRewardAddress,
    address _wethCompPriceFeed,
    address _aaveProtocolDataProvider,
    address _aavePoolAddressesProvider
);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_wethAddress`|`address`|WETH contract address|
|`_cometAddress`|`address`|Compound Comet contract address|
|`_cometRewardAddress`|`address`|Compound Comet rewards contract address|
|`_wethCompPriceFeed`|`address`|Compound WETH price feed address|
|`_aaveProtocolDataProvider`|`address`|Aave protocol data provider contract address|
|`_aavePoolAddressesProvider`|`address`|Aave lending pool addresses provider|


### depositWETH

Allow the owner to deposit to Aave and Compound

*only accepts WETH token*


```solidity
function depositWETH(uint256 _amount) external nonReentrant onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|in wei to be deposited|


### withdrawWETH

Allows the owner to withraw his asset from Aave or Compound


```solidity
function withdrawWETH() external nonReentrant onlyOwner;
```

### rebalanceWETH

Allows the caller to move the asset the protocol with higher apy


```solidity
function rebalanceWETH() external;
```

### claimCompRewards

Claims the reward tokens due to this contract address


```solidity
function claimCompRewards() public;
```

### getCompoundWETHCurrentBalance

*Returns current contract balance in Compound*


```solidity
function getCompoundWETHCurrentBalance() public view returns (uint256);
```

### receive

*contract cannot receive ether*


```solidity
receive() external payable;
```

### _recieveWETH

Transfer Weth from a sender to the contract


```solidity
function _recieveWETH(address _from, uint256 _amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_from`|`address`|The recipient address|
|`_amount`|`uint256`|The amount of tokens to transfer from the sender|


### _sendWETH

Transfer Weth from the contract to the recipient


```solidity
function _sendWETH(address _to, uint256 _amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_to`|`address`|The recipient address|
|`_amount`|`uint256`|The amount of tokens to transfer|


### _depositWETHToAave


```solidity
function _depositWETHToAave(uint256 _amount) internal;
```

### _withdrawWETHFromAave


```solidity
function _withdrawWETHFromAave() internal;
```

### _depositWETHToCompound


```solidity
function _depositWETHToCompound(uint256 _amount) internal;
```

### _withdrawWETHFromCompound


```solidity
function _withdrawWETHFromCompound() internal;
```

### getAaveCurrentWETHAPY

*Returns Aave APY*


```solidity
function getAaveCurrentWETHAPY() public view returns (uint256);
```

### getCompoundCurrentWETHAPY

*Returns Compound APY*


```solidity
function getCompoundCurrentWETHAPY() public view returns (uint256);
```

### getAaveWETHCurrentBalance

*Returns current contract balance in Aave*


```solidity
function getAaveWETHCurrentBalance() public view returns (uint256);
```

### getCompoundPrice

Get the current price of an asset from the protocol's persepctive


```solidity
function getCompoundPrice(address singleAssetPriceFeed) public view returns (uint256);
```

