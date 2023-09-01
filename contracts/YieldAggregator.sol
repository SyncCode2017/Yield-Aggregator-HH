// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";
import "@aave/core-v3/contracts/interfaces/IPoolDataProvider.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/periphery-v3/contracts/rewards/interfaces/IRewardsController.sol";
import {Comet} from "./interfaces/IComet.sol";
import {CometRewards} from "./interfaces/IComet.sol";
import {CometStructs} from "./interfaces/IComet.sol";
import "./interfaces/IYieldAggregator.sol";

/** @title A yield aggregator contract for optimising users APY in Aave and COMPOUND.
 *  @author Abolaji
 *  @dev It monitors APY of both Aave and COMPOUND and deposit the user's WETH tokens into the protocol
 *  with higher APY.
 */
contract YieldAggregator is IYieldAggregator, ReentrancyGuard, Ownable {
    using ERC165Checker for address;
    using SafeERC20 for IERC20;

    address public immutable WETH_ADDRESS;
    uint48 public constant DAYS_PER_YEAR = 365;
    uint48 public constant SECONDS_PER_DAY = 60 * 60 * 24;
    address public immutable compAddress;
    uint96 public constant SECONDS_PER_YEAR = SECONDS_PER_DAY * DAYS_PER_YEAR;
    address public immutable compRewardAddress;
    Comet public immutable COMPOUND;
    address public wethCompPriceFeed;
    uint96 public constant RAY = 10 ** 27;

    uint256 public BASE_MANTISSA;
    uint256 public BASE_INDEX_SCALE;
    uint256 public constant MAX_UINT = type(uint256).max;
    IRewardsController public aaveRewardsContract;
    IPoolAddressesProvider public immutable LENDING_POOL_ADDRESSES_PROVIDER;
    IPoolDataProvider public immutable aaveDataProvider;
    IPool public aaveLendingPool;

    /// @notice Initialises the contract
    /// @param _wethAddress WETH contract address
    /// @param _cometAddress Compound Comet contract address
    /// @param _cometRewardAddress Compound Comet rewards contract address
    /// @param _wethCompPriceFeed Compound WETH price feed address
    /// @param _aaveProtocolDataProvider Aave protocol data provider contract address
    /// @param _aavePoolAddressesProvider Aave lending pool addresses provider
    constructor(address _wethAddress, address _cometAddress, address _cometRewardAddress, address _wethCompPriceFeed, address _aaveProtocolDataProvider, address _aavePoolAddressesProvider) {
        // initialise the contract
        WETH_ADDRESS = _wethAddress;
        aaveDataProvider = IPoolDataProvider(_aaveProtocolDataProvider);
        LENDING_POOL_ADDRESSES_PROVIDER = IPoolAddressesProvider(_aavePoolAddressesProvider);
        aaveLendingPool = IPool(LENDING_POOL_ADDRESSES_PROVIDER.getPool());
        compAddress = _cometAddress;
        compRewardAddress = _cometRewardAddress;
        COMPOUND = Comet(compAddress);
        wethCompPriceFeed = _wethCompPriceFeed;
        BASE_MANTISSA = COMPOUND.baseScale();
        BASE_INDEX_SCALE = COMPOUND.baseIndexScale();
    }

    /// @notice Allow the owner to deposit to Aave and Compound
    /// @dev only accepts WETH token
    /// @param _amount in wei to be deposited
    function depositWETH(uint256 _amount) external nonReentrant onlyOwner {
        _recieveWETH(msg.sender, _amount);
        // compare the apy of Aave and Compound deposit to the one with the highest APY
        if (getAaveCurrentWETHAPY() >= getCompoundCurrentWETHAPY()) {
            _depositWETHToAave(_amount);
        } else {
            _depositWETHToCompound(_amount);
        }
    }

    /// @notice Allows the owner to withraw his asset from Aave or Compound
    function withdrawWETH() external nonReentrant onlyOwner {
        _withdrawWETHFromAave();
        _withdrawWETHFromCompound();
        uint256 _contractBalance = IERC20(WETH_ADDRESS).balanceOf(address(this));
        if (_contractBalance <= 0) revert InsufficientBalance();
        _sendWETH(owner(), _contractBalance);
        emit FundsWithdrawn(owner(), _contractBalance);
    }

    /// @notice Allows the caller to move the asset the protocol with higher apy
    function rebalanceWETH() external {
        uint256 _wethBalanceAave = getAaveWETHCurrentBalance();
        uint256 _wethBalanceCompound = getCompoundWETHCurrentBalance(); //compBalance;
        if (getAaveCurrentWETHAPY() > getCompoundCurrentWETHAPY() && _wethBalanceCompound > _wethBalanceAave) {
            _withdrawWETHFromCompound();
            uint256 _contractBalance = IERC20(WETH_ADDRESS).balanceOf(address(this));
            _depositWETHToAave(_contractBalance);
            emit FundsMovedFromCompoundToAave(_contractBalance);
        } else if (getAaveCurrentWETHAPY() < getCompoundCurrentWETHAPY() && _wethBalanceCompound < _wethBalanceAave) {
            _withdrawWETHFromAave();
            uint256 _contractBalance = IERC20(WETH_ADDRESS).balanceOf(address(this));
            _depositWETHToCompound(_contractBalance);
            emit FundsMovedFromAaveToCompound(_contractBalance);
        } else {
            revert NoRebalanceRequired();
        }
    }

    /// @notice Claims the reward tokens due to this contract address
    function claimCompRewards() public {
        try CometRewards(compRewardAddress).claim(compAddress, address(this), true) {} catch {
            revert ClaimRewardsFromCompoundFailed();
        }
    }

    /// @dev Returns current contract balance in Compound
    function getCompoundWETHCurrentBalance() public view returns (uint256) {
        uint256 _compBalance = COMPOUND.userCollateral(address(this), WETH_ADDRESS).balance;
        return _compBalance;
    }

    /// @dev contract cannot receive ether
    receive() external payable {
        revert();
    }

    /// @notice Transfer Weth from a sender to the contract
    /// @param _from The recipient address
    /// @param _amount The amount of tokens to transfer from the sender
    function _recieveWETH(address _from, uint256 _amount) internal {
        // check how much the sender has approved for this transaction
        if (IERC20(WETH_ADDRESS).allowance(_from, address(this)) < _amount) revert ApproveRightAmount();
        // receive deposit and update state
        IERC20(WETH_ADDRESS).safeTransferFrom(_from, address(this), _amount);
    }

    /// @notice Transfer Weth from the contract to the recipient
    /// @param _to The recipient address
    /// @param _amount The amount of tokens to transfer
    function _sendWETH(address _to, uint256 _amount) internal {
        address payable _recipient = payable(_to);
        // send token to the recipient
        IERC20(WETH_ADDRESS).safeTransfer(_recipient, _amount);
    }

    function _depositWETHToAave(uint256 _amount) internal {
        IERC20(WETH_ADDRESS).approve(address(aaveLendingPool), _amount);
        try aaveLendingPool.deposit(WETH_ADDRESS, _amount, address(this), 0) {
            emit FundsDepositedToAave(_amount);
        } catch {
            revert DepositToAaveFailed();
        }
    }

    function _withdrawWETHFromAave() internal {
        uint256 _amount = getAaveWETHCurrentBalance();
        if (_amount > 0) {
            try aaveLendingPool.withdraw(WETH_ADDRESS, _amount, address(this)) {
                emit FundsWithdrawnFromAave(_amount);
            } catch {
                revert AaveWithdrawalFailed();
            }
        }
    }

    function _depositWETHToCompound(uint256 _amount) internal {
        IERC20(WETH_ADDRESS).approve(address(COMPOUND), _amount);
        try COMPOUND.supply(WETH_ADDRESS, _amount) {
            emit FundsDepositedToCompound(_amount);
        } catch {
            revert DepositToCompoundFailed();
        }
    }

    function _withdrawWETHFromCompound() internal {
        uint256 _amount = getCompoundWETHCurrentBalance();
        if (_amount > 0) {
            try COMPOUND.withdraw(WETH_ADDRESS, _amount) {
                emit FundsWithdrawnFromCompound(_amount);
            } catch {
                revert CompoundWithdawalFailed();
            }
        }
    }

    /// @dev Returns Aave APY
    function getAaveCurrentWETHAPY() public view returns (uint256) {
        uint256 _userDepositAmount = RAY; // hypothetical
        DataTypes.ReserveData memory reserveData = aaveLendingPool.getReserveData(WETH_ADDRESS);
        uint256 currentLiquidityRate = reserveData.currentLiquidityRate;
        uint256 currentLiquidityIndex = reserveData.liquidityIndex;
        uint256 _depositAPR = (currentLiquidityRate * (10 ** 18)) / RAY;
        uint256 apyNumerator = (currentLiquidityIndex * _depositAPR) / _userDepositAmount;
        uint256 apyDenominator = (10 ** 18);
        uint256 apy = (apyNumerator * RAY) / apyDenominator;
        return apy;
    }

    /// @dev Returns Compound APY
    function getCompoundCurrentWETHAPY() public view returns (uint256) {
        uint256 rewardTokenPriceInUsd = getCompoundPrice(wethCompPriceFeed);
        uint256 usdcPriceInUsd = getCompoundPrice(COMPOUND.baseTokenPriceFeed());
        uint256 usdcTotalSupply = COMPOUND.totalSupply();
        uint256 baseTrackingSupplySpeed = COMPOUND.baseTrackingSupplySpeed();
        uint256 rewardToSuppliersPerDay = baseTrackingSupplySpeed * SECONDS_PER_DAY * (BASE_INDEX_SCALE / BASE_MANTISSA);
        uint256 supplyBaseRewardApr = ((rewardTokenPriceInUsd * rewardToSuppliersPerDay) / (usdcTotalSupply * usdcPriceInUsd)) * DAYS_PER_YEAR;
        return supplyBaseRewardApr * (10 ** 8);
    }

    /// @dev Returns current contract balance in Aave
    function getAaveWETHCurrentBalance() public view returns (uint256) {
        (uint256 currentATokenBalance, , , , , , , , ) = aaveDataProvider.getUserReserveData(WETH_ADDRESS, address(this));
        return currentATokenBalance;
    }

    /// @notice Get the current price of an asset from the protocol's persepctive
    function getCompoundPrice(address singleAssetPriceFeed) public view returns (uint256) {
        return COMPOUND.getPrice(singleAssetPriceFeed);
    }
}
