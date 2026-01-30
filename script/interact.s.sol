// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

/**
 * @title ClaimAirdrop
 * @author Hash-Hokage
 * @notice Script to claim airdrop tokens from the MerkleAirdrop contract
 * @dev This script automates the airdrop claiming process by:
 *      1. Finding the most recently deployed MerkleAirdrop contract
 *      2. Splitting the pre-signed signature into v, r, s components
 *      3. Executing the claim transaction with the Merkle proof
 *
 *      Usage:
 *      1. Update CLAIMING_ADDRESS and SIGNATURE with valid values
 *      2. Ensure PROOF matches the address in the Merkle tree
 *      3. Run: `forge script script/interact.s.sol:ClaimAirdrop --broadcast`
 *
 *      Prerequisites:
 *      - The CLAIMING_ADDRESS must be whitelisted in the Merkle tree
 *      - The SIGNATURE must be a valid EIP-712 signature from CLAIMING_ADDRESS
 *      - The MerkleAirdrop contract must have sufficient token balance
 */
contract ClaimAirdrop is Script {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address eligible to claim the airdrop tokens
    /// @dev Default: Anvil's first account (0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)
    address CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    /// @notice The amount of tokens to claim (25 tokens with 18 decimals)
    uint256 CLAIMING_AMOUNT = 25 * 1e18;

    /// @notice First element of the Merkle proof for the claiming address
    bytes32 PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;

    /// @notice Second element of the Merkle proof for the claiming address
    bytes32 PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;

    /// @notice Complete Merkle proof array for claim verification
    bytes32[] PROOF = [PROOF_ONE, PROOF_TWO];

    /// @notice Pre-signed EIP-712 signature authorizing the claim
    /// @dev Must be signed by the CLAIMING_ADDRESS private key
    bytes private SIGNATURE =
        hex"f508354fd9dc387f7ba76ffa6999f63cedd29eb768b54ef21106292e56f179016ed2961889e74c45e0073bf2f5f1e14e02728367966a75751f850d0412ae69cf1c";

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the provided signature is not exactly 65 bytes
    error _ClaimAidropScript_invalidSignatureLength();

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Claims airdrop tokens from a deployed MerkleAirdrop contract
     * @dev Splits the signature and calls the claim function with all required parameters
     * @param airdropAddress The address of the deployed MerkleAirdrop contract
     */
    function claimAirdrop(address airdropAddress) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirdrop(airdropAddress).claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, PROOF, v, r, s);
        vm.stopBroadcast();
    }

    /**
     * @notice Splits an ECDSA signature into its v, r, s components
     * @dev Uses inline assembly for gas-efficient extraction of signature components
     * @param sig The complete ECDSA signature (65 bytes)
     * @return v The recovery identifier (27 or 28)
     * @return r The first 32 bytes of the signature
     * @return s The second 32 bytes of the signature
     */
    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert _ClaimAidropScript_invalidSignatureLength();
        }
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /**
     * @notice Entry point for the claim script
     * @dev Uses DevOpsTools to find the most recently deployed MerkleAirdrop contract
     *      on the current chain and executes the claim
     */
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("merkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployed);
    }
}
