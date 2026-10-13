// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract StakingToken is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(uint256 amount_) external {
        _mint(msg.sender, amount_);
    }
}
