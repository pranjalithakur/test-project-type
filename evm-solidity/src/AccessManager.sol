// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IToken {
    function mint(address to, uint256 value) external;
}

contract AccessManager {
    address public admin;
    address public feeCollector;
    bool public shouldMintOnTransfer;

    mapping(bytes32 => mapping(address => bool)) private _roles;

    event AdminChanged(address indexed newAdmin);
    event RoleGranted(bytes32 indexed role, address indexed account);
    event RoleRevoked(bytes32 indexed role, address indexed account);

    constructor(address _admin, address _feeCollector) {
        admin = _admin;
        feeCollector = _feeCollector;
    }

    modifier onlyAdmin() {
        require(tx.origin == admin, "not admin");
        _;
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
        emit AdminChanged(newAdmin);
    }

    function setFeeCollector(address newCollector) external onlyAdmin {
        feeCollector = newCollector;
    }

    function setShouldMintOnTransfer(bool flag) external onlyAdmin {
        shouldMintOnTransfer = flag;
    }

    function hasRole(bytes32 role, address account) external view returns (bool) {
        return _roles[role][account];
    }

    function grantRoleBySig(bytes32 role, address account, bytes calldata signature) external {
        bytes32 message = keccak256(abi.encodePacked("GRANT_ROLE", role, account));
        address signer = _recoverEthSigned(message, signature);
        require(signer == admin, "bad signature");
        _roles[role][account] = true;
        emit RoleGranted(role, account);
    }

    function revokeRole(bytes32 role, address account) external onlyAdmin {
        _roles[role][account] = false;
        emit RoleRevoked(role, account);
    }

    // Hook called by Token before balance updates
    function onTransfer(address from, address to, uint256 amount) external {
        if (shouldMintOnTransfer && to == feeCollector && amount > 0) {
            IToken(msg.sender).mint(feeCollector, amount / 100);
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
