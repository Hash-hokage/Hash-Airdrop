// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";

/**
 * @title GenerateInput
 * @author Hash-Hokage
 * @notice Generates the input JSON file for Merkle tree construction
 * @dev This script creates a structured JSON file containing the whitelist addresses
 *      and their corresponding airdrop amounts. The output is consumed by MakeMerkle.s.sol
 *      to generate the Merkle tree and proofs.
 *
 *      Usage:
 *      1. Modify the whitelist array with eligible addresses
 *      2. Adjust AMOUNT if needed (currently 25 tokens per address)
 *      3. Run: `forge script script/GenerateInput.s.sol`
 *      4. Output will be written to /script/target/input.json
 *
 *      JSON Structure:
 *      {
 *        "types": ["address", "uint"],
 *        "count": 4,
 *        "values": {
 *          "0": { "0": "address", "1": "amount" },
 *          ...
 *        }
 *      }
 */
contract GenerateInput is Script {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Amount of tokens each whitelisted address can claim (25 tokens with 18 decimals)
    uint256 private constant AMOUNT = 25 * 1e18;

    /// @notice Relative path to the output JSON file from project root
    string private constant INPUT_PATH = "/script/target/input.json";

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Array of data types for each leaf node element
    /// @dev ["address", "uint"] represents the structure: (address account, uint256 amount)
    string[] types = new string[](2);

    /// @notice Number of whitelisted addresses
    uint256 count;

    /// @notice Array of whitelisted addresses eligible for the airdrop
    string[] whitelist = new string[](4);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Entry point for the input generation script
     * @dev Initializes the whitelist and types arrays, then generates and writes the JSON file
     *
     *      Current Whitelist:
     *      - 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D
     *      - 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (Anvil default account)
     *      - 0x2ea3970Ed82D5b30be821FAAD4a731D35964F7dd
     *      - 0xf6dBa02C01AF48Cf926579F77C9f874Ca640D91D
     */
    function run() public {
        types[0] = "address";
        types[1] = "uint";
        whitelist[0] = "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D";
        whitelist[1] = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
        whitelist[2] = "0x2ea3970Ed82D5b30be821FAAD4a731D35964F7dd";
        whitelist[3] = "0xf6dBa02C01AF48Cf926579F77C9f874Ca640D91D";
        count = whitelist.length;
        string memory input = _createJSON();
        // Write to the output file the stringified output JSON tree dump
        vm.writeFile(string.concat(vm.projectRoot(), INPUT_PATH), input);

        console.log("DONE: The output is found at %s", INPUT_PATH);
    }

    /**
     * @notice Creates the JSON string from the whitelist data
     * @dev Manually constructs the JSON structure without using external libraries
     *      to ensure compatibility with Foundry's cheatcodes
     * @return The complete JSON string ready to be written to file
     */
    function _createJSON() internal view returns (string memory) {
        string memory countString = vm.toString(count);
        string memory amountString = vm.toString(AMOUNT);
        string memory json = string.concat('{ "types": ["address", "uint"], "count":', countString, ',"values": {');
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (i == whitelist.length - 1) {
                json = string.concat(
                    json,
                    '"',
                    vm.toString(i),
                    '"',
                    ': { "0":',
                    '"',
                    whitelist[i],
                    '"',
                    ', "1":',
                    '"',
                    amountString,
                    '"',
                    " }"
                );
            } else {
                json = string.concat(
                    json,
                    '"',
                    vm.toString(i),
                    '"',
                    ': { "0":',
                    '"',
                    whitelist[i],
                    '"',
                    ', "1":',
                    '"',
                    amountString,
                    '"',
                    " },"
                );
            }
        }
        json = string.concat(json, "} }");

        return json;
    }
}
