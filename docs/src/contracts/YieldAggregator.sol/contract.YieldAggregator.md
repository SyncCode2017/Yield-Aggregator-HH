# YieldAggregator
[Git Source](https://github.com/SyncCode2017/yield-aggregator-hh/blob/01148571bb2766461391b15c703f4fd7ab15471a/contracts/YieldAggregator.sol)

**Inherits:**
[IYieldAggregator](/contracts/interfaces/IYieldAggregator.sol/interface.IYieldAggregator.md), ReentrancyGuard, Ownable

**Author:**
Abolaji

*It monitors APY of both Aave and compoundComet and deposit the user's WETH tokens into the protocol
with higher APY.*


## State Variables
### wethAddress
*WETH contract address*


```solidity
address public immutable wethAddress;
```


### DAYS_PER_YEAR
*Number of days in a year*


```solidity
uint48 public constant DAYS_PER_YEAR = 365;
```


### SECONDS_PER_DAY
*Seconds in a day*


```solidity
uint48 public constant SECONDS_PER_DAY = 60 * 60 * 24;
```


### compAddress
*Compound V3 comet contract address*


```solidity
address public immutable compAddress;
```


### SECONDS_PER_YEAR
*Seconds in a year*


```solidity
uint96 public constant SECONDS_PER_YEAR = SECONDS_PER_DAY * DAYS_PER_YEAR;
```


### compRewardAddress
*Compound rewards contract address*


```solidity
address public immutable compRewardAddress;
```


### compoundComet
*Compound V3 comet contract*


```solidity
Comet public immutable compoundComet;
```


### RAY

```solidity
uint96 public constant RAY = 10 ** 27;
```


### MAX_UINT

```solidity
uint256 public constant MAX_UINT = type(uint256).max;
```


### lendingPoolAddressProvider
*Aave V3 lending pool address provider*


```solidity
IPoolAddressesProvider public immutable lendingPoolAddressProvider;
```


### aaveDataProvider
*Aave V3 data provider contract*


```solidity
IPoolDataProvider public immutable aaveDataProvider;
```


### aaveLendingPool
*Aave V3 lending pool contract*


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

### getAaveCurrentWETHAPY

*Returns current Aave APY*


```solidity
function getAaveCurrentWETHAPY() public view returns (uint256);
```

### getCompoundCurrentWETHAPY

*Returns current Compound WETH APY*


```solidity
function getCompoundCurrentWETHAPY() public view returns (uint256);
```

### getAaveWETHCurrentBalance

*Returns current contract balance in Aave*


```solidity
function getAaveWETHCurrentBalance() public view returns (uint256);
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

*Supplies WETH asset to Aave V3 protocol*


```solidity
function _depositWETHToAave(uint256 _amount) internal;
```

### _withdrawWETHFromAave

*Withdraws WETH asset from Compound V3 protocol*


```solidity
function _withdrawWETHFromAave() internal;
```

### _depositWETHToCompound

*Supplies WETH asset to Compound V3 protocol*


```solidity
function _depositWETHToCompound(uint256 _amount) internal;
```

### _withdrawWETHFromCompound

*Withdraws WETH asset from Aave V3 protocol*


```solidity
function _withdrawWETHFromCompound() internal;
```

