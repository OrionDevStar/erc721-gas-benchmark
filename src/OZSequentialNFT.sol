// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @notice Control implementation using the same OpenZeppelin ERC-721 core as
/// the enumerable baseline, but sequential IDs and no ERC721Enumerable storage.
/// This isolates the cost of enumerable bookkeeping from unrelated mint logic.
contract OZSequentialNFT is ERC721 {
    uint256 private _nextTokenId;

    constructor() ERC721("OZ Sequential Benchmark", "OZSB") {}

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
