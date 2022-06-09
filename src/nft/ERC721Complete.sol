// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721MintableBurnableAccessControlEnumerable.sol";

contract ERC721Complete is ERC721MintableBurnableAccessControlEnumerable {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721MintableBurnableAccessControlEnumerable(name, symbol, baseTokenURI) {
        _registerInterface(type(IERC165).interfaceId);
        _registerInterface(type(IAccessControl).interfaceId);
        _registerInterface(type(IAccessControlEnumerable).interfaceId);
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721Metadata).interfaceId);
        _registerInterface(type(IERC721Enumerable).interfaceId);
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}
