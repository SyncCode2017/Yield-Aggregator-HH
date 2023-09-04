# IWETH
[Git Source](https://github.com/SyncCode2017/yield-aggregator-hh/blob/b0c4faacf958598cfd8e723937511d7ce489672f/contracts/interfaces/IWETH.sol)


## Functions
### allowance


```solidity
function allowance(address owner, address spender) external view returns (uint256 remaining);
```

### approve


```solidity
function approve(address spender, uint256 value) external returns (bool success);
```

### balanceOf


```solidity
function balanceOf(address owner) external view returns (uint256 balance);
```

### decimals


```solidity
function decimals() external view returns (uint8 decimalPlaces);
```

### name


```solidity
function name() external view returns (string memory tokenName);
```

### symbol


```solidity
function symbol() external view returns (string memory tokenSymbol);
```

### totalSupply


```solidity
function totalSupply() external view returns (uint256 totalTokensIssued);
```

### transfer


```solidity
function transfer(address to, uint256 value) external returns (bool success);
```

### transferFrom


```solidity
function transferFrom(address from, address to, uint256 value) external returns (bool success);
```

### deposit


```solidity
function deposit() external payable;
```

### withdraw


```solidity
function withdraw(uint256 wad) external;
```

