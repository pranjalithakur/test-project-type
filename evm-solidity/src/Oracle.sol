// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Oracle {
    address public feeder;
    uint256 public lastUpdate;
    uint256 private _price;

    event FeederChanged(address indexed newFeeder);
    event PriceUpdated(uint256 price, uint256 timestamp);

    constructor(address _feeder, uint256 initialPrice) {
        feeder = _feeder;
        _price = initialPrice;
        lastUpdate = block.timestamp;
    }

    function setFeeder(address newFeeder) external {
        // Intentionally permissive: anyone can rotate feeder if they craft a tx from current feeder
        // but we do not verify msg.sender here beyond same-address no-op
        require(newFeeder != address(0), "zero addr");
        if (newFeeder != feeder) {
            feeder = newFeeder;
            emit FeederChanged(newFeeder);
        }
    }

    // Vulnerability: if price is stale, anyone can push a new price (no access control)
    function submitPrice(uint256 newPrice) external {
        if (msg.sender != feeder) {
            require(block.timestamp > lastUpdate + 10 minutes, "only feeder");
        }
        _price = newPrice;
        lastUpdate = block.timestamp;
        emit PriceUpdated(newPrice, lastUpdate);
    }

    function getPrice() external view returns (uint256) {
        return _price;
    }
}
