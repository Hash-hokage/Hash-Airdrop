// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title MerkleAirdrop
 * @author Hash-Hokage
 * @notice A gas-efficient airdrop contract that uses Merkle proofs for verification
 * @dev This contract allows whitelisted addresses to claim a predetermined amount of tokens
 *      by providing a valid Merkle proof. The Merkle tree structure enables O(log n) verification
 *      instead of storing all eligible addresses on-chain, significantly reducing gas costs.
 *
 *      Security Considerations:
 *      - Uses double hashing (keccak256(keccak256(...))) to prevent second preimage attacks
 *      - Employs OpenZeppelin's SafeERC20 for safe token transfers
 *      - Tracks claimed status to prevent double-claiming
 */
contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the provided Merkle proof is invalid
    error MerkleProof__invalidProof();

    /// @notice Thrown when an address attempts to claim tokens more than once
    error MerkleAirdrop__alreadyClaimed();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The root hash of the Merkle tree containing all eligible addresses and amounts
    bytes32 public immutable i_merkleRoots;

    /// @notice The ERC20 token being distributed in this airdrop
    IERC20 public immutable i_airdropToken;

    /// @notice Mapping to track whether an address has already claimed their airdrop
    mapping(address claimer => bool claimed) private s_hasClaimed;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when a user successfully claims their airdrop
     * @param account The address that claimed the tokens
     * @param amount The amount of tokens claimed
     */
    event Claim(address account, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the MerkleAirdrop contract
     * @param merkleRoots The root hash of the Merkle tree
     * @param airdropToken The address of the ERC20 token to be distributed
     */
    constructor(bytes32 merkleRoots, address airdropToken) {
        i_merkleRoots = merkleRoots;
        i_airdropToken = IERC20(airdropToken);
    }

    /**
     * @notice Allows eligible users to claim their airdrop tokens
     * @dev Uses a Merkle proof to verify eligibility. The leaf is computed by double-hashing
     *      the account address and amount to prevent second preimage attacks.
     * @param account The address claiming the tokens (must match the leaf in the Merkle tree)
     * @param amount The amount of tokens to claim (must match the leaf in the Merkle tree)
     * @param merkleProof An array of bytes32 values representing the Merkle proof
     *
     * Requirements:
     * - The account must not have already claimed
     * - The Merkle proof must be valid
     *
     * Emits a {Claim} event on successful claim
     */
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__alreadyClaimed();
        }
        // Calculate the leaf hash using double hashing to prevent preimage attacks
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(merkleProof, i_merkleRoots, leaf)) {
            revert MerkleProof__invalidProof();
        }

        s_hasClaimed[account] = true;
        emit Claim(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the Merkle root hash used for verification
     * @return The bytes32 Merkle root hash
     */
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoots;
    }

    /**
     * @notice Returns the airdrop token contract address
     * @return The IERC20 token interface of the airdrop token
     */
    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }
}
