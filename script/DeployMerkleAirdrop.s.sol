// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop, IERC20} from "../src/MerkleAirdrop.sol";
import {HashToken} from "../src/HashToken.sol";

/**
 * @title DeployMerkleAirdrop
 * @author Hash-Hokage
 * @notice Deployment script for the MerkleAirdrop and HashToken contracts
 * @dev This script deploys both contracts and sets up the initial token distribution.
 *      The Merkle root is pre-computed from the whitelist data and hardcoded for deployment.
 *
 *      Deployment Flow:
 *      1. Deploy HashToken contract
 *      2. Deploy MerkleAirdrop contract with the Merkle root and token address
 *      3. Mint tokens to the owner
 *      4. Transfer tokens to the airdrop contract for distribution
 */
contract DeployMerkleAirdrop is Script {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The Merkle root hash computed from the whitelist addresses and amounts
    /// @dev Generated using the MakeMerkle.s.sol script from the input.json file
    bytes32 private s_merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    /// @notice Total amount of tokens to mint and transfer to the airdrop contract
    /// @dev Calculated as 4 users * 25 tokens each = 100 tokens (with 18 decimals)
    uint256 private s_amountToTransfer = 4 * 25 * 1e18;

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deploys the MerkleAirdrop and HashToken contracts
     * @dev Performs the following steps:
     *      1. Deploys a new HashToken contract
     *      2. Deploys a new MerkleAirdrop contract with the pre-computed Merkle root
     *      3. Mints the total airdrop amount to the token owner
     *      4. Transfers the minted tokens to the airdrop contract
     * @return airdrop The deployed MerkleAirdrop contract instance
     * @return hashToken The deployed HashToken contract instance
     */
    function deployMerkleAirdrop() public returns (MerkleAirdrop, HashToken) {
        vm.startBroadcast();
        HashToken hashToken = new HashToken();
        MerkleAirdrop airdrop = new MerkleAirdrop(s_merkleRoot, address(IERC20(hashToken)));
        hashToken.mint(hashToken.owner(), s_amountToTransfer);
        hashToken.transfer(address(airdrop), s_amountToTransfer);
        vm.stopBroadcast();
        return (airdrop, hashToken);
    }

    /**
     * @notice Entry point for the deployment script
     * @dev Called by `forge script` command
     * @return airdrop The deployed MerkleAirdrop contract instance
     * @return hashToken The deployed HashToken contract instance
     */
    function run() external returns (MerkleAirdrop, HashToken) {
        return deployMerkleAirdrop();
    }
}
