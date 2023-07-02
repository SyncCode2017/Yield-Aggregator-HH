// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICompoundV3 {
    function getAPY(address asset) external view returns (uint256);

    function deposit(address asset, uint256 amount) external returns (bool);

    function withdraw(address asset, uint256 amount) external returns (bool);

    function getBalance(address asset) external view returns (uint256);

    function getAccruedInterest(address asset) external returns (uint256);

    function claimComp(address holder) external returns (bool);
}