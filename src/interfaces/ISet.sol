// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ISetRead {
    function has(uint256 data) external view returns (bool);

    function size() external view returns (uint256);

    function getItem(uint256 index) external view returns (bool, uint256);
}

interface ISetWrite {
    function add(uint256 data) external;

    function remove(uint256 data) external;
}

interface ISet is ISetRead, ISetWrite {}
