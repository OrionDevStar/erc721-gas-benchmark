// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title Historical ERC721S benchmark implementation
/// @notice Faithful minimal adaptation of OrionDevStar's 2021 sequential ERC-721
/// ownership architecture, based on the verified Oddies Club contract.
///
/// The production contract also included OpenSea proxy integration,
/// meta-transactions, metadata/reveal logic, payment splitting, and project-specific
/// mint rules. Those features are intentionally omitted here because they are not
/// part of the storage optimization being benchmarked.
///
/// Core 2021 design preserved here:
/// - tokenId is the index of `_owners`
/// - minting appends the owner address to `_owners`
/// - no per-owner balance mapping
/// - no enumerable ownership/global token arrays
/// - balance/enumeration are calculated at read time by scanning `_owners`
contract HistoricalERC721S is ERC165, IERC721, IERC721Enumerable {
    using Address for address;

    address[] internal _owners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner)
        public
        view
        override
        returns (uint256 balance)
    {
        require(owner != address(0), "ERC721: balance query for zero address");
        unchecked {
            uint256 length = _owners.length;
            for (uint256 i; i < length; ++i) {
                if (_owners[i] == owner) ++balance;
            }
        }
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        return _owners[tokenId];
    }

    function totalSupply() public view override returns (uint256 supply) {
        unchecked {
            uint256 length = _owners.length;
            for (uint256 tokenId; tokenId < length; ++tokenId) {
                if (_owners[tokenId] != address(0)) ++supply;
            }
        }
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256 tokenId)
    {
        uint256 length = _owners.length;
        unchecked {
            for (; tokenId < length; ++tokenId) {
                if (_owners[tokenId] == owner && index-- == 0) break;
            }
        }
        require(tokenId < length, "ERC721Enumerable: owner index out of bounds");
    }

    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256 tokenId)
    {
        uint256 length = _owners.length;
        unchecked {
            for (; tokenId < length; ++tokenId) {
                if (_owners[tokenId] != address(0) && index-- == 0) break;
            }
        }
        require(tokenId < length, "ERC721Enumerable: global index out of bounds");
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(msg.sender != operator, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
    {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
    {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function mint(address to, uint256 quantity) external {
        for (uint256 i; i < quantity; ) {
            _safeMint(to);
            unchecked {
                ++i;
            }
        }
    }

    function _safeMint(address to) internal returns (uint256 tokenId) {
        tokenId = _mint(to);
        require(
            _checkOnERC721Received(address(0), to, tokenId, ""),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to) internal returns (uint256 tokenId) {
        require(to != address(0), "ERC721: mint to zero address");
        tokenId = _owners.length;
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token not owned");
        require(to != address(0), "ERC721: transfer to zero address");
        _approve(address(0), tokenId);
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _owners.length && _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return
            spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (!to.isContract()) return true;

        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data)
            returns (bytes4 retval)
        {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch {
            return false;
        }
    }
}
