# ERC-721 Gas Benchmark

A reproducible benchmark of the storage overhead associated with enumerable ERC-721 implementations commonly used during the 2021 NFT market.

This project revisits an optimization problem I worked on in 2021: NFT contracts frequently inherited OpenZeppelin's `ERC721Enumerable`, which provides convenient on-chain enumeration but requires additional bookkeeping whenever tokens are minted or transferred.

My production work at the time explored sequential-token architectures that reduced this storage overhead. This repository isolates that design decision so the gas difference can be measured under the same compiler, optimizer, mint logic, and test environment.

## What is being compared?

### `OZEnumerableNFT`
Uses OpenZeppelin `ERC721Enumerable`, representing the conventional enumerable architecture used by many NFT collections of the period.

### `OZSequentialNFT`
Uses the same OpenZeppelin ERC-721 core and the same sequential mint loop, but does **not** inherit `ERC721Enumerable`.

This is intentionally a conservative control. It does not claim to reproduce every optimization in my original 2021 implementation. Its purpose is to isolate the gas cost of enumerable storage bookkeeping before benchmarking the original sequential architecture separately.

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
forge test --gas-report
```

For a clean comparison, use the same toolchain revision for both implementations.

## Scenarios

| Operation | Enumerable | Sequential |
| --- | --- | --- |
| Mint 1 NFT | benchmarked | benchmarked |
| Mint 5 NFTs | benchmarked | benchmarked |
| Mint 10 NFTs | benchmarked | benchmarked |
| Transfer 1 NFT | benchmarked | benchmarked |

The test suite deliberately keeps business logic out of both contracts. There is no whitelist, mint price, royalties, reveal logic, or project-specific code affecting one implementation differently from the other.

## Results

Results will be added here after running the benchmark with the pinned OpenZeppelin version.

| Operation | OZ ERC721Enumerable | Sequential ERC721 | Gas saved | Reduction |
| --- | ---: | ---: | ---: | ---: |
| Mint 1 | TBD | TBD | TBD | TBD |
| Mint 5 | TBD | TBD | TBD | TBD |
| Mint 10 | TBD | TBD | TBD | TBD |
| Transfer 1 | TBD | TBD | TBD | TBD |

No percentage will be published until it is produced by the reproducible benchmark.

## Why `ERC721Enumerable` costs more

Enumeration is not free. An enumerable implementation must maintain additional state so contracts can answer questions such as which token exists at a global index or which token belongs to an owner at a particular index.

Those conveniences require additional storage bookkeeping during state-changing operations such as minting and transferring.

When token IDs are sequential and the application does not require those enumeration structures to be maintained on every write, some information can instead be derived from the token sequence or computed when queried. The trade-off is straightforward:

> **Reduce expensive state-changing storage operations, accept more expensive or less convenient enumeration reads.**

For high-volume NFT minting in 2021, that trade-off could materially affect transaction costs.

## Historical context

This benchmark was inspired by my 2021 work on a gas-optimized sequential ERC-721 implementation deployed on Ethereum Mainnet.

[Verified production contract on Etherscan](https://etherscan.io/address/0xbbc93a41f78a11d0779171f270fc86ee8efb3765#code)

The production implementation and this benchmark are not presented as identical contracts. The benchmark starts with a deliberately narrow comparison so individual sources of gas savings can be measured rather than attributing unrelated contract differences to the sequential architecture.

## Next step

The next benchmark stage will add a faithful minimal reproduction of the original `ERC721S` / `ERC721SE` ownership model and compare it against both OpenZeppelin baselines.

That will separate two questions:

1. How much gas does removing `ERC721Enumerable` bookkeeping save?
2. How much additional gas did the original sequential ownership architecture save?

## License

MIT
