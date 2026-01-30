// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

/**
 * @title SplitSignature
 * @author Hash-Hokage
 * @notice Utility script to split ECDSA signatures into their v, r, s components
 * @dev This script reads a signature from a file and splits it for use with
 *      the MerkleAirdrop claim function. ECDSA signatures are 65 bytes:
 *      - r: bytes 0-31 (32 bytes)
 *      - s: bytes 32-63 (32 bytes)
 *      - v: byte 64 (1 byte, recovery identifier)
 *
 *      Usage:
 *      1. Save your signature to signature.txt (hex format without 0x prefix)
 *      2. Run: `forge script script/SplitSignature.s.sol`
 *      3. Use the output v, r, s values in the claim function
 */
contract SplitSignature is Script {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the provided signature is not exactly 65 bytes
    error __SplitSignatureScript__InvalidSignatureLength();

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Splits an ECDSA signature into its v, r, s components
     * @dev Uses inline assembly for gas-efficient extraction of signature components.
     *      The signature must be exactly 65 bytes in the standard format.
     * @param sig The complete ECDSA signature (65 bytes)
     * @return v The recovery identifier (27 or 28)
     * @return r The first 32 bytes of the signature
     * @return s The second 32 bytes of the signature
     */
    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert __SplitSignatureScript__InvalidSignatureLength();
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Entry point for the signature splitting script
     * @dev Reads a signature from signature.txt, splits it, and logs the components
     *      The signature file should contain hex bytes without the 0x prefix
     */
    function run() external {
        string memory sig = vm.readFile("signature.txt");
        bytes memory sigBytes = vm.parseBytes(sig);
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sigBytes);
        console.log("v value:");
        console.log(v);
        console.log("r value:");
        console.logBytes32(r);
        console.log("s value:");
        console.logBytes32(s);
    }
}
