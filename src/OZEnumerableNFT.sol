// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// @notice Baseline representing the common enumerable ERC-721 architecture
/// used by NFT collections in 2021.
contract OZEnumerableNFT is ERC721Enumerable {
    uint256 private _nextTokenId;

    constructor() ERC721("OZ Enumerable Benchmark", "OZEB") {}

    function mint(address to, uint256 quantity) external {
        for (uint256 i; i < quantity; ) {
            _safeMint(to, _nextTokenId);
            unchecked {
                ++_nextTokenId;
                ++i;
            }
        }
    }
}
