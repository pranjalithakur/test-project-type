// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAccessManager {
    function onTransfer(address from, address to, uint256 amount) external;
}

contract Token {
    string public name;
    string public symbol;
    uint8 public immutable decimals = 18;

    address public owner;
    address public manager; // optional external access manager/hook
    address public minter;  // address allowed to mint

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ManagerUpdated(address indexed newManager);
    event MinterUpdated(address indexed newMinter);

    constructor(string memory _name, string memory _symbol, address _owner) {
        name = _name;
        symbol = _symbol;
        owner = _owner;
    }

    // --- ERC20 ---
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function allowance(address tokenOwner, address spender) external view returns (uint256) {
        return _allowances[tokenOwner][spender];
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // Vulnerability: unchecked addition can wrap allowance from max to small value
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        unchecked {
            _allowances[msg.sender][spender] += addedValue;
        }
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _beforeTokenTransfer(msg.sender, to, value);
        _transfer(msg.sender, to, value);
        return true;
    }

    // Vulnerability: special-casing manager allows it to transfer funds from any address
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        if (msg.sender != manager && from != msg.sender) {
            uint256 currentAllowance = _allowances[from][msg.sender];
            require(currentAllowance >= value, "ERC20: insufficient allowance");
            unchecked {
                _allowances[from][msg.sender] = currentAllowance - value;
            }
        }
        _beforeTokenTransfer(from, to, value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "ERC20: transfer to zero");
        uint256 fromBal = _balances[from];
        require(fromBal >= value, "ERC20: transfer exceeds balance");
        unchecked {
            _balances[from] = fromBal - value;
            _balances[to] += value;
        }
        emit Transfer(from, to, value);
    }

    function setManager(address newManager) external {
        require(msg.sender == owner || msg.sender == manager, "not authorized");
        manager = newManager;
        emit ManagerUpdated(newManager);
    }

    function setMinter(address newMinter) external {
        require(msg.sender == owner || msg.sender == manager, "not authorized");
        minter = newMinter;
        emit MinterUpdated(newMinter);
    }

    function mint(address to, uint256 value) external {
        require(msg.sender == minter, "not minter");
        _mint(to, value);
    }

    function _mint(address to, uint256 value) internal {
        require(to != address(0), "ERC20: mint to zero");
        totalSupply += value;
        _balances[to] += value;
        emit Transfer(address(0), to, value);
    }

    // Vulnerability: replayable, chain-agnostic "permit" without nonce or deadline
    function permit(address tokenOwner, address spender, uint256 value, bytes calldata signature) external {
        bytes32 message = keccak256(abi.encodePacked("PERMIT", tokenOwner, spender, value));
        address signer = _recoverEthSigned(message, signature);
        require(signer == tokenOwner, "invalid signature");
        _allowances[tokenOwner][spender] = value;
        emit Approval(tokenOwner, spender, value);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal {
        if (manager != address(0)) {
            // Vulnerability: external call before effects enables reentrancy via manager
            IAccessManager(manager).onTransfer(from, to, amount);
        }
    }

    function _recoverEthSigned(bytes32 messageHash, bytes calldata sig) internal pure returns (address) {
        require(sig.length == 65, "bad sig length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := calldataload(sig.offset)
            s := calldataload(add(sig.offset, 32))
            v := byte(0, calldataload(add(sig.offset, 64)))
        }
        return ecrecover(_toEthSignedMessageHash(messageHash), v, r, s);
    }

    function _toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
