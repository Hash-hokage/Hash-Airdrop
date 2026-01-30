// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {HashToken} from "../src/HashToken.sol";
import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";

/**
 * @title MerkleAirdropTest
 * @author Hash-Hokage
 * @notice Test suite for the MerkleAirdrop and HashToken contracts
 * @dev Tests the core functionality of the airdrop claiming mechanism.
 *      Supports both standard EVM chains and ZkSync chains with conditional setup.
 *
 *      Test Coverage:
 *      - User claim functionality with valid Merkle proofs
 *      - Integration with the deployment script
 */
contract MerkleAirdropTest is Test, ZkSyncChainChecker {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Instance of the MerkleAirdrop contract under test
    MerkleAirdrop airdrop;

    /// @notice Instance of the HashToken contract under test
    HashToken token;

    /// @notice The Merkle root hash matching the deployment configuration
    bytes32 ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    /// @notice Amount each user can claim from the airdrop (25 tokens with 18 decimals)
    uint256 public AMOUNT_TO_CLAIM = 25 * 1e18;

    /// @notice Total amount to send to the airdrop contract (4 users * 25 tokens)
    uint256 public AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;

    /// @notice First proof element for the test user's Merkle proof
    bytes32 public proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;

    /// @notice Second proof element for the test user's Merkle proof
    bytes32 public proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;

    /// @notice Complete Merkle proof array for claim verification
    bytes32[] public PROOF = [proofOne, proofTwo];

    /// @notice Address that pays gas fees for claim transactions (meta-transaction relayer)
    address gasPayer;

    /// @notice Test user address (derived from the whitelist)
    address user;

    /// @notice Test user's private key for signing (if needed)
    uint256 userPrivKey;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets up the test environment before each test
     * @dev Conditionally deploys contracts based on the chain type:
     *      - Standard EVM: Uses the deployment script for realistic testing
     *      - ZkSync: Deploys contracts directly due to script limitations
     */
    function setUp() public {
        if (!isZkSyncChain()) {
            // Deploy with script for standard EVM chains
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, token) = deployer.deployMerkleAirdrop();
        } else {
            // Direct deployment for ZkSync chains
            token = new HashToken();
            airdrop = new MerkleAirdrop(ROOT, address(token));
            token.mint(token.owner(), AMOUNT_TO_SEND);
            token.transfer(address(airdrop), AMOUNT_TO_SEND);
        }
        // Set user with a known private key for signing in both paths
        (user, userPrivKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }

    /*//////////////////////////////////////////////////////////////
                                 TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that a whitelisted user can successfully claim their airdrop
     * @dev Verifies the complete claim flow:
     *      1. User starts with zero token balance
     *      2. User calls claim with valid proof
     *      3. User receives the expected amount of tokens
     */
    function testUserCanClaimAirdrop() public {
        uint256 startingBalance = token.balanceOf(user);
        bytes32 digest = airdrop.getMessageHash(user, AMOUNT_TO_CLAIM);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, digest);

        vm.prank(gasPayer);
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);

        uint256 endingBalance = token.balanceOf(user);
        console.log("EndingBalance:", endingBalance);
        assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM);
    }
}
