# ERC-721 Gas Benchmark

A reproducible benchmark revisiting a gas-optimization problem I worked on during the 2021 NFT market: reducing the storage overhead of enumerable ERC-721 contracts by using sequential token IDs and deriving enumeration data at read time.

The benchmark compares a period-appropriate OpenZeppelin `ERC721Enumerable`, a conservative OpenZeppelin sequential control, and a minimal reconstruction of my 2021 `ERC721S` / `ERC721SE` ownership architecture.

## Implementations

### `OZEnumerableNFT`
Uses OpenZeppelin `ERC721Enumerable`, representing the conventional enumerable architecture used by many NFT collections of the period.

### `OZSequentialNFT`
Uses the same OpenZeppelin ERC-721 core and sequential IDs, but does not inherit `ERC721Enumerable`. This isolates the cost of enumerable bookkeeping.

### `HistoricalERC721S`
A minimal benchmark adaptation of the sequential ownership architecture used in my verified 2021 production contract.

Its core design stores ownership in an `address[] _owners`, where the array index is the token ID. It does not maintain a separate balance mapping or the usual per-owner/global enumerable token structures. Balance and enumeration information are instead calculated at read time.

Project-specific features from the production contract—payments, metadata/reveal logic, OpenSea proxy integration, meta-transactions, and collection mint rules—are intentionally excluded because they are unrelated to the storage optimization being measured.

## Environment

- Solidity: `0.8.10`
- Optimizer: enabled
- Optimizer runs: `200`
- OpenZeppelin Contracts: `v4.4.1`
- Framework: Foundry

## Run the benchmark

Install Foundry, clone the repository, then install the historical OpenZeppelin dependency:

```bash
forge install OpenZeppelin/openzeppelin-contracts@v4.4.1
```

Run:

```bash
forge test -vv
forge test --gas-report
```

## Results

Results below come from isolated Foundry test scenarios using the same compiler and optimizer configuration.

| Operation | OZ Enumerable | OZ Sequential | Historical ERC721S | ERC721S reduction vs Enumerable |
| --- | ---: | ---: | ---: | ---: |
| Mint 1 | 109,237 | 77,445 | **54,792** | **49.84%** |
| Mint 5 | 568,912 | 179,366 | **153,680** | **72.99%** |
| Mint 10 | 1,143,463 | 306,737 | **277,310** | **75.75%** |

For the isolated `transferFrom` function reported by Foundry's gas report:

| Operation | OZ Enumerable | OZ Sequential | Historical ERC721S | ERC721S reduction vs Enumerable |
| --- | ---: | ---: | ---: | ---: |
| `transferFrom` | 65,540 | 57,381 | **39,029** | **40.45%** |

Deployment also becomes smaller:

| Contract | Deployment gas | Bytecode size |
| --- | ---: | ---: |
| OZ Enumerable | 1,445,971 | 6,605 bytes |
| OZ Sequential | 1,220,918 | 5,563 bytes |
| Historical ERC721S | **1,024,755** | **4,531 bytes** |

That is a **29.13% reduction in deployment gas** versus the enumerable baseline.

### What the benchmark shows

The conservative OpenZeppelin sequential control already demonstrates that removing enumerable bookkeeping produces a large improvement for batch minting. The historical architecture goes further.

Compared with the enumerable baseline, the reconstructed 2021 ownership model uses approximately:

- **49.84% less gas** for a 1-token mint;
- **72.99% less gas** for a 5-token mint;
- **75.75% less gas** for a 10-token mint;
- **40.45% less gas** for `transferFrom`;
- **29.13% less gas** to deploy the benchmark contract.

It also outperforms the conservative non-enumerable OpenZeppelin control in these scenarios. For example, the historical implementation reduces the 1-token mint by another **29.25%** relative to that control.

## Why the architecture saves gas

Traditional enumerable ERC-721 implementations maintain additional on-chain structures so contracts can cheaply answer questions such as which token belongs to an owner at a given index or which token exists at a global index.

The 2021 sequential architecture makes a different trade-off. Token IDs are implicit in the position of an ownership array:

```solidity
uint256 tokenId = _owners.length;
_owners.push(to);
```

That means minting does not need to update a separate token-ID counter, owner balance mapping, per-owner token list, global token list, and their associated index mappings in the same way as the enumerable baseline.

Enumeration remains available, but is calculated by scanning ownership at read time.

> **The design moves work away from expensive state-changing storage writes and toward read-time computation.**

That trade-off was particularly relevant for NFT drops, where users directly paid the transaction cost of minting.

## Methodology and limitations

This is a controlled architecture benchmark, not a claim that every real-world NFT transaction would be 75.75% cheaper.

Both baselines and the historical implementation are tested with deliberately minimal mint logic. Whitelists, royalties, payment handling, metadata, reveal mechanics, and other project-specific behavior are excluded.

`HistoricalERC721S` is a minimal reconstruction of the ownership/enumeration architecture from the verified production source, not a byte-for-byte copy of the entire deployed Oddies Club contract. This makes the comparison narrower and avoids attributing unrelated application logic to the storage optimization.

Gas figures can also vary with EVM/toolchain changes, so results should be reproduced with the pinned environment when comparing numbers.

## Historical context

This benchmark was inspired by my 2021 work on a gas-optimized sequential ERC-721 implementation deployed on Ethereum Mainnet.

[Verified 2021 production contract on Etherscan](https://etherscan.io/address/0xbbc93a41f78a11d0779171f270fc86ee8efb3765#code)

The verified production source preserves the historical implementation and attribution. This repository exists to make the architectural trade-off easier to inspect and reproduce under controlled conditions.

## License

MIT
