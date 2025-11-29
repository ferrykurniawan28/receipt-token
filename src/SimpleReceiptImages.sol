// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SimpleReceiptImages is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // HANYA SIMPAN CID SAJA
    mapping(uint256 => string) public imageCIDs;
    mapping(string => bool) public cidExists; // Prevent duplicate CIDs

    event ImageStored(
        uint256 indexed tokenId,
        address indexed uploadedBy,
        string imageCID
    );

    constructor() ERC721("SimpleReceipts", "SRCPT") {}

    // FUNCTION SANGAT SIMPLE: Hanya terima CID
    function storeReceiptImage(string memory _imageCID) external returns (uint256) {
        require(!cidExists[_imageCID], "CID already exists");
        require(bytes(_imageCID).length > 0, "CID required");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        // Mint NFT
        _safeMint(msg.sender, tokenId);
        
        // Generate token URI dengan image CID - FIXED: renamed variable
        string memory generatedTokenURI = _generateTokenURI(_imageCID);
        _setTokenURI(tokenId, generatedTokenURI);

        // SIMPAN CID SAJA
        imageCIDs[tokenId] = _imageCID;
        cidExists[_imageCID] = true;

        emit ImageStored(tokenId, msg.sender, _imageCID);
        return tokenId;
    }

    // Generate token URI dengan image CID
    function _generateTokenURI(string memory _imageCID) internal pure returns (string memory) {
        string memory json = string(abi.encodePacked(
            '{"name": "Receipt Image",',
            '"description": "Stored receipt image on blockchain",',
            '"image": "ipfs://', _imageCID, '"}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            _base64(bytes(json))
        ));
    }

    // Base64 encoding (simple version)
    function _base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        bytes memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        bytes memory result = new bytes(encodedLen + 32);
        assembly {
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return string(result);
    }

    // GETTER FUNCTIONS
    function getImageCID(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "Token doesn't exist");
        return imageCIDs[tokenId];
    }

    function getImageURL(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "Token doesn't exist");
        return string(abi.encodePacked("https://gateway.pinata.cloud/ipfs/", imageCIDs[tokenId]));
    }

    function totalImages() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // Override required functions
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // ADD THIS FUNCTION TO RESOLVE THE CONFLICT
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(ERC721, ERC721URIStorage) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}