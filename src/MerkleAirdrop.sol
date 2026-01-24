// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

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
contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the provided Merkle proof is invalid
    error MerkleProof__invalidProof();

    /// @notice Thrown when an address attempts to claim tokens more than once
    error MerkleAirdrop__alreadyClaimed();

    /// @notice thrown when the provided signature is invalid
    error MerkleAirdrop__invalidSignature();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The root hash of the Merkle tree containing all eligible addresses and amounts
    bytes32 public immutable i_merkleRoots;

    /// @notice The ERC20 token being distributed in this airdrop
    IERC20 public immutable i_airdropToken;

    /// @notice Mapping to track whether an address has already claimed their airdrop
    mapping(address claimer => bool claimed) private s_hasClaimed;

    bytes32 public constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

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
    constructor(bytes32 merkleRoots, address airdropToken) EIP712("HashAirdrop", "1") {
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
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__alreadyClaimed();
        }

        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__invalidSignature();
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

    /**
     * @notice Computes the EIP-712 typed data hash for an airdrop claim
     * @dev Uses the EIP-712 standard for structured data hashing to create
     *      a message that can be signed off-chain and verified on-chain
     * @param account The address of the claimer
     * @param amount The amount of tokens being claimed
     * @return The EIP-712 compliant message hash ready for signing
     */
    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount}))));
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

    /**
     * @notice Verifies that a signature was created by the expected account
     * @dev Uses ECDSA recovery to extract the signer from the signature components
     *      and compares it against the expected account address
     * @param account The address expected to have signed the message
     * @param digest The EIP-712 typed data hash that was signed
     * @param v The recovery identifier (27 or 28)
     * @param r The r component of the ECDSA signature
     * @param s The s component of the ECDSA signature
     * @return True if the recovered signer matches the expected account, false otherwise
     */
    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == account;
    }
}
