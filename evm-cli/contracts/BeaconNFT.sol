// SPDX-License-Identifier: JSSH-2026-0001
pragma solidity ^0.8.24;

/// @title BeaconNFT - Minimal ERC-721 for loan identification
/// @notice Self-contained implementation to avoid OpenZeppelin v5 compatibility issues
contract BeaconNFT {
    string public name = "ZER Beacon";
    string public symbol = "ZBEACON";
    
    uint256 private _tokenIdCounter;
    address public owner;
    
    enum TokenType { BorrowerId, LenderId, LoanId }
    
    struct TokenInfo {
        TokenType tokenType;
        address minter;
        uint256 linkedId;
        bool active;
    }
    
    mapping(uint256 => TokenInfo) public tokenInfo;
    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => string) public tokenURI;
    mapping(address => uint256[]) public tokensOf;
    mapping(address => bool) public minters;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event BeaconMinted(uint256 indexed tokenId, TokenType tokenType, address indexed to);
    event BeaconBurned(uint256 indexed tokenId);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Not minter");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        minters[msg.sender] = true;
    }
    
    /// @notice Authorize a contract (e.g. Loan) to mint/burn beacons
    function setMinter(address minter) external onlyOwner {
        require(minters[msg.sender], "Not owner");
        minters[minter] = true;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return tokensOf[account].length;
    }
    
    function ownerOf(uint256 tokenId) public view returns (address) {
        require(tokenOwner[tokenId] != address(0), "Token does not exist");
        return tokenOwner[tokenId];
    }
    
    function mintBorrowerId(address to, uint256 linkedId) external onlyMinter returns (uint256) {
        uint256 tokenId = _tokenIdCounter++;
        _mint(to, tokenId, TokenType.BorrowerId, linkedId);
        return tokenId;
    }
    
    function mintLenderId(address to, uint256 linkedId) external onlyMinter returns (uint256) {
        uint256 tokenId = _tokenIdCounter++;
        _mint(to, tokenId, TokenType.LenderId, linkedId);
        return tokenId;
    }
    
    function mintLoanId(uint256 loanId, address borrower, address lender) external onlyMinter returns (uint256) {
        uint256 tokenId = _tokenIdCounter++;
        _mint(lender, tokenId, TokenType.LoanId, loanId);
        return tokenId;
    }
    
    function borrowerBeacon(address minter, uint256 linkedId) external onlyMinter {
        _burnByLinkedId(minter, TokenType.BorrowerId, linkedId);
    }
    
    function lenderBeacon(address minter, uint256 linkedId) external onlyMinter {
        _burnByLinkedId(minter, TokenType.LenderId, linkedId);
    }
    
    function burnLoanId(uint256 loanId) external onlyMinter {
        uint256[] storage tokens = tokensOf[address(this)];
        // Iterate backwards: _burn swap-and-pops, moving an already-checked element into the slot
        for (uint256 i = tokens.length; i > 0; i--) {
            uint256 tokenId = tokens[i - 1];
            if (tokenInfo[tokenId].linkedId == loanId && tokenInfo[tokenId].active) {
                _burn(tokenId);
            }
        }
    }
    
    function burnForUnlock(uint256 loanId, address minter) external onlyMinter {
        uint256[] storage tokens = tokensOf[minter];
        // Iterate backwards: _burn swap-and-pops, moving an already-checked element into the slot
        for (uint256 i = tokens.length; i > 0; i--) {
            uint256 tokenId = tokens[i - 1];
            if (tokenInfo[tokenId].linkedId == loanId && 
                tokenInfo[tokenId].tokenType != TokenType.LoanId &&
                tokenInfo[tokenId].active) {
                _burn(tokenId);
            }
        }
    }
    
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter;
    }
    
    // Internal functions
    function _mint(address to, uint256 tokenId, TokenType tokenType, uint256 linkedId) internal {
        tokenOwner[tokenId] = to;
        tokenInfo[tokenId] = TokenInfo(tokenType, to, linkedId, true);
        tokensOf[to].push(tokenId);
        emit Transfer(address(0), to, tokenId);
        emit BeaconMinted(tokenId, tokenType, to);
    }
    
    function _burn(uint256 tokenId) internal {
        address tokenAddress = tokenOwner[tokenId];
        tokenInfo[tokenId].active = false;
        delete tokenOwner[tokenId];
        
        uint256[] storage arr = tokensOf[tokenAddress];
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == tokenId) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
                break;
            }
        }
        
        emit Transfer(tokenAddress, address(0), tokenId);
        emit BeaconBurned(tokenId);
    }
    
    function _burnByLinkedId(address minter, TokenType tokenType, uint256 linkedId) internal {
        uint256[] storage arr = tokensOf[minter];
        for (uint256 i = 0; i < arr.length; i++) {
            if (tokenInfo[arr[i]].linkedId == linkedId && 
                tokenInfo[arr[i]].tokenType == tokenType &&
                tokenInfo[arr[i]].active) {
                _burn(arr[i]);
                break;
            }
        }
    }
}
