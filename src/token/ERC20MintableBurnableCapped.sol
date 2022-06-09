// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract ERC20MintableBurnableCapped is ERC20, AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    uint256 private immutable _cap;

    constructor(string memory name_, string memory symbol_, uint256 cap_) ERC20(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        _mint(to, amount);
    }

    function burnFrom(address from, uint256 amount) external onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }
}