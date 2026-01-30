# Hash-Airdrop 

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.24-blue.svg)](https://docs.soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg)](https://getfoundry.sh/)

A gas-efficient Merkle airdrop smart contract system with EIP-712 signature verification and ZkSync support.

## Overview

Hash-Airdrop enables token distribution to thousands of recipients with minimal gas costs using Merkle tree verification. Instead of storing all eligible addresses on-chain, it stores a single 32-byte Merkle root, allowing O(log n) proof verification.

### Key Features

- **Gas Efficient**: Merkle tree verification reduces on-chain storage costs
- **Signature-Based Claims**: EIP-712 signatures enable meta-transactions (gasless claims for users)
- **Double-Hash Protection**: Prevents second preimage attacks on leaf nodes
- **ZkSync Compatible**: Full support for ZkSync Era deployment and interaction
- **Comprehensive Tooling**: Scripts for Merkle tree generation, signature splitting, and claim automation

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Hash-Airdrop System                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐     ┌──────────────────┐     ┌──────────────┐ │
│  │  HashToken  │────▶│  MerkleAirdrop   │◀────│    Claimer   │ │
│  │   (ERC20)   │     │   (Distributor)  │     │  (User/Bot)  │ │
│  └─────────────┘     └──────────────────┘     └──────────────┘ │
│                              │                       │          │
│                              ▼                       ▼          │
│                      ┌──────────────┐        ┌─────────────┐   │
│                      │ Merkle Root  │        │  EIP-712    │   │
│                      │ Verification │        │  Signature  │   │
│                      └──────────────┘        └─────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Contracts

| Contract | Description |
|----------|-------------|
| `MerkleAirdrop.sol` | Core airdrop contract with Merkle proof and signature verification |
| `HashToken.sol` | ERC20 token with owner-controlled minting |

## Installation

### Prerequisites

- [Foundry](https://getfoundry.sh/) - Smart contract development toolkit
- [Node.js](https://nodejs.org/) - Required for ZkSync CLI (optional)

### Setup

```bash
# Clone the repository
git clone https://github.com/Hash-Hokage/Hash-Airdrop.git
cd Hash-Airdrop

# Install dependencies
forge install

# Build contracts
forge build
```

## Usage

### 1. Generate Merkle Tree

First, update the whitelist in `GenerateInput.s.sol`, then generate the Merkle tree:

```bash
# Generate input.json with whitelist data
forge script script/GenerateInput.s.sol:GenerateInput

# Generate Merkle root and proofs
forge script script/MakeMerkle.s.sol:MakeMerkle

# Or run both in one command
make merkle
```

Output files are saved to `script/target/`:
- `input.json` - Whitelist addresses and amounts
- `output.json` - Merkle root and proofs for each address

### 2. Deploy Contracts

```bash
# Deploy to local Anvil
make deploy

# Deploy to Sepolia
make deploy ARGS="--network sepolia"

# Deploy to ZkSync local
make deploy-zk
```

### 3. Claim Airdrop

**Option A: Using Makefile (Anvil)**

```bash
# Get signature for claim
make sign

# Execute claim transaction
make claim

# Check token balance
make balance
```

**Option B: Using Scripts**

```bash
# Sign the claim message
cast wallet sign --no-hash --private-key <PRIVATE_KEY> $(cast call <AIRDROP_ADDRESS> "getMessageHash(address,uint256)" <YOUR_ADDRESS> <AMOUNT>)

# Run claim script
forge script script/interact.s.sol:ClaimAirdrop --broadcast
```

### 4. ZkSync Deployment

For ZkSync Era, use the automated shell script:

```bash
# Start ZkSync local node
make zk-anvil

# Run full deployment and claim flow
./interactZk.sh
```

## Testing

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run ZkSync-specific tests
make zktest

# Generate gas report
forge test --gas-report
```

## Security Considerations

### Merkle Tree Security
- **Double Hashing**: Leaf nodes use `keccak256(bytes.concat(keccak256(abi.encode(account, amount))))` to prevent second preimage attacks
- **Immutable Root**: The Merkle root is set at deployment and cannot be modified

### Token Security
- **SafeERC20**: Uses OpenZeppelin's SafeERC20 for safe token transfers
- **Claim Tracking**: Prevents double-claiming via `s_hasClaimed` mapping

### Signature Security
- **EIP-712**: Typed structured data hashing prevents signature replay across contracts/chains
- **ECDSA Recovery**: Uses OpenZeppelin's ECDSA library with `tryRecover` for safe signature verification

## Project Structure

```
├── src/
│   ├── MerkleAirdrop.sol      # Core airdrop contract
│   └── HashToken.sol          # ERC20 token contract
├── script/
│   ├── DeployMerkleAirdrop.s.sol  # Deployment script
│   ├── GenerateInput.s.sol        # Whitelist JSON generator
│   ├── MakeMerkle.s.sol           # Merkle tree generator
│   ├── SplitSignature.s.sol       # Signature utility
│   └── interact.s.sol             # Claim automation script
├── test/
│   └── MerkleAirdrop.t.sol    # Test suite
├── interactZk.sh              # ZkSync deployment automation
└── Makefile                   # Command shortcuts
```

## Dependencies

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) - ERC20, SafeERC20, ECDSA, MerkleProof, EIP712
- [Murky](https://github.com/dmfxyz/murky) - Merkle tree generation library
- [Foundry DevOps](https://github.com/Cyfrin/foundry-devops) - Deployment utilities

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Hash-Hokage**

---

> ⚠️ **Disclaimer**: This code is provided as-is for educational purposes. Always conduct thorough audits before deploying to production.
