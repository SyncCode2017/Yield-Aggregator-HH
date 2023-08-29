// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
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
// import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "hardhat/console.sol";

error ApproveRightAmount();
error InsufficientBalance();
error NoAaveRewardsClaimed();
error DepositToAaveFailed();
error AaveWithdrawalFailed();
error DepositToCompoundFailed();
error CompoundWithdawalFailed();
error ClaimRewardsFromCompoundFailed();
error ClaimAaveRewardsFailed();

/** @title A yield aggregator contract for optimising users APY in Aave and
 * COMPOUND.
 *  @author Abolaji
 *  @dev It monitors APY in both Aave and COMPOUND
 */

contract YieldAggregator is ReentrancyGuard, Ownable {
    // defensive as not required after pragma ^0.8
    using SafeMath for uint256;
    using ERC165Checker for address;
    using SafeERC20 for IERC20;
    // using FixedPoint for *;

    address public immutable WETH_ADDRESS;
    address public immutable compAddress;
    address public immutable compRewardAddress;
    Comet public immutable COMPOUND;
    address public wethCompPriceFeed;
    uint public constant DAYS_PER_YEAR = 365;
    uint public constant SECONDS_PER_DAY = 60 * 60 * 24;
    uint public constant RAY = 10 ** 27;
    uint224 public constant UNITY = 1;
    uint public constant SECONDS_PER_YEAR = SECONDS_PER_DAY * DAYS_PER_YEAR;
    uint public BASE_MANTISSA;
    uint public BASE_INDEX_SCALE;
    uint public constant MAX_UINT = type(uint).max;
    IRewardsController public aaveRewardsContract;

    IPoolAddressesProvider public immutable LENDING_POOL_ADDRESSES_PROVIDER;

    IPoolDataProvider public immutable aaveDataProvider;
    IPool public aaveLendingPool;

    uint256 public compBalance;

    //Events
    event FundsWithdrawn(address _owner, uint256 _amount, uint256 _time);
    event FundsDepositedToAave(uint256 _amount, uint256 _time);
    event FundsWithdrawnFromAave(uint256 _amount, uint256 _time);
    event FundsDepositedToCompound(uint256 _amount, uint256 _time);
    event FundsWithdrawnFromCompound(uint256 _amount, uint256 _time);

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

    /// @notice Contribute fund on behalf of another address for the open campaign.
    /// @dev only accepts ERC-20 deposit when campaign is open
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

    /// @notice Funds are released to the authorised business wallet based on the
    /// milestone schedule.
    /// @dev Only the authorised business wallet can withdraw
    function withdrawWETH() external nonReentrant onlyOwner {
        _withdrawWETHFromAave();
        _withdrawWETHFromCompound();
        uint256 _contractBalance = IERC20(WETH_ADDRESS).balanceOf(address(this));
        if (_contractBalance <= 0) revert InsufficientBalance();
        _sendWETH(owner(), _contractBalance);
        emit FundsWithdrawn(owner(), _contractBalance, block.timestamp);
    }

    function rebalanceWETH() external {
        uint256 _wethBalanceAave = getAaveWETHCurrentBalance();
        updateCompoundWETHCurrentBalance();
        uint256 _wethBalanceCompound = compBalance;

        if (getAaveCurrentWETHAPY() > getCompoundCurrentWETHAPY() && _wethBalanceCompound > _wethBalanceAave) {
            _withdrawWETHFromCompound();
            uint256 _contractBalance = IERC20(WETH_ADDRESS).balanceOf(address(this));
            _depositWETHToAave(_contractBalance);
        } else if (getAaveCurrentWETHAPY() < getCompoundCurrentWETHAPY() && _wethBalanceCompound < _wethBalanceAave) {
            _withdrawWETHFromAave();
            uint256 _contractBalance = IERC20(WETH_ADDRESS).balanceOf(address(this));
            _depositWETHToCompound(_contractBalance);
        }
    }

    /// @dev returns Aave APY
    function getAaveCurrentWETHAPY() public view returns (uint256) {
        DataTypes.ReserveData memory reserveData = aaveLendingPool.getReserveData(WETH_ADDRESS);
        uint256 currentLiquidityRate = reserveData.currentLiquidityRate;
        console.log("currentLiquidityRate", currentLiquidityRate);
        return currentLiquidityRate;
        //FixedPoint.uq112x112 memory _depositAPR = FixedPoint.fraction(currentLiquidityRate, RAY);
        // uint256 _depositAPR = currentLiquidityRate / RAY;
        // console.log("_depositAPR", _depositAPR);

        // FixedPoint.uq112x112 memory depositAPY = FixedPoint.uq112x112(uint224((UNITY.add(uint224(FixedPoint.fraction(_depositAPR, SECONDS_PER_YEAR)))) ** SECONDS_PER_YEAR) - UNITY);
        // console.log("depositAPY", depositAPY);
        //return depositAPY;
    }

    /*
     * Get the current reward for supplying APR in Compound III
     * @param rewardTokenPriceFeed The address of the reward token (e.g. COMP) price feed
     * @return The reward APR in USD as a decimal scaled up by 1e18
     */
    function getCompoundCurrentWETHAPY() public view returns (uint256) {
        uint rewardTokenPriceInUsd = getCompoundPrice(wethCompPriceFeed);
        uint usdcPriceInUsd = getCompoundPrice(COMPOUND.baseTokenPriceFeed());
        uint usdcTotalSupply = COMPOUND.totalSupply();
        uint baseTrackingSupplySpeed = COMPOUND.baseTrackingSupplySpeed();
        uint rewardToSuppliersPerDay = baseTrackingSupplySpeed * SECONDS_PER_DAY * (BASE_INDEX_SCALE / BASE_MANTISSA);
        uint supplyBaseRewardApr = ((rewardTokenPriceInUsd * rewardToSuppliersPerDay) / (usdcTotalSupply * usdcPriceInUsd)) * DAYS_PER_YEAR;
        return supplyBaseRewardApr * (10 ** 8);
    }

    /// @dev returns current contract balance in Compound
    function updateCompoundWETHCurrentBalance() public {
        compBalance = COMPOUND.userCollateral(address(this), WETH_ADDRESS).balance + getCompUnclaimedRewards();
        console.log("compoundBalance", compBalance);
        //return _userBalance;
    }

    /// @dev returns current contract balance in Aave
    function getAaveWETHCurrentBalance() public view returns (uint256) {
        (uint256 totalCollateralBase, , , , , ) = aaveLendingPool.getUserAccountData(address(this));
        console.log("totalCollateralBase", totalCollateralBase * (10 * 27));
        return totalCollateralBase;
    }

    /// @dev contract can receive ether
    receive() external payable {
        // revert();
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
            emit FundsDepositedToAave(_amount, block.timestamp);
        } catch {
            revert DepositToAaveFailed();
        }
    }

    function _withdrawWETHFromAave() internal {
        uint256 _collateralAmount = getAaveWETHCurrentBalance();
        uint256 _rewardsAmount = getAaveUnclaimedRewards();
        if (_rewardsAmount > 0) {
            claimAaveRewards();
        }
        if (_collateralAmount > 0) {
            try aaveLendingPool.withdraw(WETH_ADDRESS, _collateralAmount, address(this)) {
                emit FundsWithdrawnFromAave(_collateralAmount.add(_rewardsAmount), block.timestamp);
            } catch {
                revert AaveWithdrawalFailed();
            }
        }
    }

    function _depositWETHToCompound(uint256 _amount) internal {
        IERC20(WETH_ADDRESS).approve(address(COMPOUND), _amount);
        try COMPOUND.supply(WETH_ADDRESS, _amount) {
            emit FundsDepositedToCompound(_amount, block.timestamp);
        } catch {
            revert DepositToCompoundFailed();
        }
    }

    function _withdrawWETHFromCompound() internal {
        updateCompoundWETHCurrentBalance();
        uint256 _collateralAmount = compBalance;
        uint256 _rewardsAmount = getCompUnclaimedRewards();
        if (_rewardsAmount > 0) {
            claimCompRewards();
        }
        if (_collateralAmount > 0) {
            try COMPOUND.withdraw(WETH_ADDRESS, _collateralAmount) {
                emit FundsWithdrawnFromCompound(_collateralAmount.add(_rewardsAmount), block.timestamp);
            } catch {
                revert CompoundWithdawalFailed();
            }
        }
    }

    /*
     * Get the current price of an asset from the protocol's persepctive
     */
    function getCompoundPrice(address singleAssetPriceFeed) public view returns (uint) {
        return COMPOUND.getPrice(singleAssetPriceFeed);
    }

    /*
     * Get the price feed address for an asset
     */
    function getCompPriceFeedAddress(address asset) public view returns (address) {
        return COMPOUND.getAssetInfoByAddress(asset).priceFeed;
    }

    /*
     * Gets the amount of reward tokens due to this contract address
     */
    function getCompUnclaimedRewards() public returns (uint256) {
        return CometRewards(compRewardAddress).getRewardOwed(compAddress, address(this)).owed;
    }

    /*
     * Claims the reward tokens due to this contract address
     */
    function claimAaveRewards() public {
        address[] memory _wethAddress;
        _wethAddress[0] = WETH_ADDRESS;
        // (, uint256[] memory _amounts) = aaveRewardsContract.claimAllRewardsToSelf(_wethAddress);
        // if (_amounts.length == 0) revert NoAaveRewardsClaimed();
        try aaveRewardsContract.claimAllRewardsToSelf(_wethAddress) {} catch {
            revert ClaimAaveRewardsFailed();
        }
    }

    /*
     * Claims the reward tokens due to this contract address
     */
    function claimCompRewards() public {
        try CometRewards(compRewardAddress).claim(compAddress, address(this), true) {} catch {
            revert ClaimRewardsFromCompoundFailed();
        }
    }

    function getAaveUnclaimedRewards() public view returns (uint256) {
        (, , , , , , uint256 liquidityRate, , ) = aaveDataProvider.getUserReserveData(WETH_ADDRESS, address(this));
        //try aaveDataProvider.getUserReserveData(WETH_ADDRESS, address(this)) returns (, , , , , , uint256 liquidityRate, , ) {} catch {}
        uint256 unclaimedRewards = (liquidityRate * getAaveWETHCurrentBalance()) / (10 ** 18);
        return unclaimedRewards;
    }
}
