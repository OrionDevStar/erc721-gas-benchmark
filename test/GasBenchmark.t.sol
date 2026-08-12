// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../src/OZEnumerableNFT.sol";
import "../src/OZSequentialNFT.sol";

/// @notice Benchmark scenarios intentionally contain only one measured action
/// per test so `forge test --gas-report` produces easy-to-compare results.
contract GasBenchmarkTest {
    address internal constant RECIPIENT = address(0xBEEF);
    address internal constant SECOND_RECIPIENT = address(0xCAFE);

    OZEnumerableNFT internal enumerable;
    OZSequentialNFT internal sequential;

    function setUp() public {
        enumerable = new OZEnumerableNFT();
        sequential = new OZSequentialNFT();
    }

    function testEnumerableMint1() public {
        enumerable.mint(RECIPIENT, 1);
    }

    function testSequentialMint1() public {
        sequential.mint(RECIPIENT, 1);
    }

    function testEnumerableMint5() public {
        enumerable.mint(RECIPIENT, 5);
    }

    function testSequentialMint5() public {
        sequential.mint(RECIPIENT, 5);
    }

    function testEnumerableMint10() public {
        enumerable.mint(RECIPIENT, 10);
    }

    function testSequentialMint10() public {
        sequential.mint(RECIPIENT, 10);
    }

    function testEnumerableTransfer() public {
        enumerable.mint(address(this), 1);
        enumerable.transferFrom(address(this), SECOND_RECIPIENT, 0);
    }

    function testSequentialTransfer() public {
        sequential.mint(address(this), 1);
        sequential.transferFrom(address(this), SECOND_RECIPIENT, 0);
    }

    // Required because _safeMint checks ERC721Receiver when minting to this contract.
    function onERC721Received(address, address, uint256, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }
}
