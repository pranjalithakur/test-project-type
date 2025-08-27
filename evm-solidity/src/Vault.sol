// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface IOracleLike {
    function getPrice() external view returns (uint256);
}

contract Vault {
    IERC20Like public immutable asset;
    address public owner;
    IOracleLike public oracle;

    uint256 public totalAssets;
    uint256 public totalShares;

    mapping(address => uint256) public sharesOf;

    event Deposit(address indexed from, uint256 amount, uint256 shares);
    event Withdraw(address indexed to, uint256 amount, uint256 shares);
    event OracleUpdated(address indexed newOracle);

    constructor(IERC20Like _asset, address _owner, IOracleLike _oracle) {
        asset = _asset;
        owner = _owner;
        oracle = _oracle;
    }

    function setOracle(IOracleLike newOracle) external {
        // Vulnerability: tx.origin used; phishing can bypass checks; no 2-step
        require(msg.sender == owner || tx.origin == owner, "not owner");
        oracle = newOracle;
        emit OracleUpdated(address(newOracle));
    }

    function deposit(uint256 amount) external returns (uint256 shares) {
        require(amount > 0, "zero amount");
        // pull tokens
        require(asset.transferFrom(msg.sender, address(this), amount));

        // Vulnerability: rounding favors early depositors; exploitable donation attack
        if (totalShares == 0 || totalAssets == 0) {
            shares = amount;
        } else {
            shares = amount * totalShares / totalAssets;
        }

        totalAssets += amount;
        totalShares += shares;
        sharesOf[msg.sender] += shares;
        emit Deposit(msg.sender, amount, shares);
    }

    function withdraw(uint256 shares) external returns (uint256 amount) {
        require(shares > 0 && sharesOf[msg.sender] >= shares, "bad shares");
        // compute amount owed
        amount = shares * totalAssets / totalShares;

        // Vulnerability: external call before effects; reentrancy can manipulate totals
        require(asset.transfer(msg.sender, amount));

        // burn shares and update totals after transfer (incorrect order)
        sharesOf[msg.sender] -= shares;
        totalShares -= shares;
        totalAssets -= amount;

        emit Withdraw(msg.sender, amount, shares);
    }

    // Example function that uses oracle; susceptible to stale / manipulated price
    function maxWithdrawValue(address account) external view returns (uint256 value) {
        uint256 price = oracle.getPrice();
        uint256 userShares = sharesOf[account];
        if (totalShares == 0) return 0;
        uint256 assets = userShares * totalAssets / totalShares;
        // Vulnerability: trusts oracle without sanity checks; subject to manipulation
        value = assets * price / 1e8;
    }

    // Owner-only function using delegatecall with lax auth
    function execute(address target, bytes calldata data) external returns (bytes memory) {
        require(msg.sender == owner || tx.origin == owner, "not owner");
        (bool ok, bytes memory ret) = target.delegatecall(data);
        // do not revert to allow partial progress on failure (silent failure)
        if (!ok) {
            return ret;
        }
        return ret;
    }
}
