 // SPDX-License-Identifier: GPL-3.0
 pragma solidity ^0.7.6;
 pragma experimental ABIEncoderV2;
 import "../library/safemath.sol";
 import "../interface/IERC721.sol";
 import "./nftMachineFactory.sol";
 
 contract NFTMachineOwnership is NFTMachineFactory, IERC721{
    using SafeMath for uint256;
     
    mapping (uint => address) public nftMachineApprovals;

    function balanceOf(address _owner) public view override returns (uint256 _balance) {
        return ownerNFTMachineCount[_owner];
    }
    
    function ownerOf(uint256 _tokenId) public view override returns (address _owner) {
        return NFTMachineToOwner[_tokenId];
    }
    
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownerNFTMachineCount[_to] = ownerNFTMachineCount[_to].add(1);
        ownerNFTMachineCount[_from] = ownerNFTMachineCount[_from].sub(1);
        NFTMachineToOwner[_tokenId] = _to;
        AddTokenIdToInfoMgr(_tokenId,_to);
        delTokenIdToInfoMgr(_tokenId,_from);
        emit Transfer(_from, _to, _tokenId);  
    }
    
    function transfer(address _to, uint256 _tokenId) public override onlyOwnerOf(_tokenId) {
        _transfer(msg.sender, _to, _tokenId);
    }
    
    function approve(address _to, uint256 _tokenId) public override onlyOwnerOf(_tokenId) {
        nftMachineApprovals[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }


    
    function takeOwnership(uint256 _tokenId) public override{
        require(nftMachineApprovals[_tokenId] == msg.sender);
        address owner = ownerOf(_tokenId);
        _transfer(owner, msg.sender, _tokenId);
    }
 }