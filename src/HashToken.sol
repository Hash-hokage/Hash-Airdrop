// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title HashToken
 * @author Hash-Hokage
 * @notice A simple ERC20 token with owner-restricted minting functionality
 * @dev Extends OpenZeppelin's ERC20 and Ownable contracts.
 *      This token is designed to be used with the MerkleAirdrop contract
 *      for distributing tokens to whitelisted addresses.
 *
 *      Token Details:
 *      - Name: "hash"
 *      - Symbol: "HASH"
 *      - Decimals: 18 (default)
 */
contract HashToken is ERC20, Ownable {
    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the HashToken contract
     * @dev Sets the token name to "hash" and symbol to "HASH".
     *      The deployer becomes the initial owner of the contract.
     */
    constructor() ERC20("hash", "HASH") Ownable(msg.sender) {}

    /**
     * @notice Mints new tokens to a specified address
     * @dev Only the contract owner can call this function
     * @param to The address to receive the minted tokens
     * @param amount The amount of tokens to mint (in wei, with 18 decimals)
     *
     * Requirements:
     * - Caller must be the contract owner
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
