pragma solidity ^0.7.6;

import "./nftMachineOwnership.sol";
import "../library/safemath.sol";
pragma experimental ABIEncoderV2;




contract NFTMarket is NFTMachineOwnership{
    

    
    address public eFILAddress;
    
    using SafeMath for uint256;
    
   struct NFTMachineSales{
        address payable seller;
        uint price;
    }
    mapping(uint=>NFTMachineSales) public NFTMachineShop;
    uint[] public nftIndexMgr;

    uint shopNFTMachineCount;
   
   bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

    event SaleNFTMachine(uint indexed NFTMachineId,address indexed seller);
    event BuyShopNFTMachine(uint indexed NFTMachineId,address indexed buyer,address indexed seller);
    
    
    constructor(){
        admin = msg.sender;
    }

    function saleNFTMachine(uint _NFTMachineId,uint _price)public onlyOwnerOf(_NFTMachineId){
        
        NFTMachineShop[_NFTMachineId] = NFTMachineSales(msg.sender,_price);
        shopNFTMachineCount = shopNFTMachineCount.add(1);
        nftIndexMgr.push(_NFTMachineId);
        emit SaleNFTMachine(_NFTMachineId,msg.sender);
    }
    function buyShopNFTMachine(uint _NFTMachineId,uint _price)public {
       require(msg.sender !=NFTMachineShop[_NFTMachineId].seller,"cant buy self");
       require(_price >=NFTMachineShop[_NFTMachineId].price,"too samll" );
       
       _safeTransfer(msg.sender,NFTMachineShop[_NFTMachineId].seller,NFTMachineShop[_NFTMachineId].price);
       
        _transfer(NFTMachineShop[_NFTMachineId].seller,msg.sender, _NFTMachineId);
       
        delete NFTMachineShop[_NFTMachineId];
        shopNFTMachineCount = shopNFTMachineCount.sub(1);

        require(deleteIndex(_NFTMachineId));

        emit BuyShopNFTMachine(_NFTMachineId,msg.sender,NFTMachineShop[_NFTMachineId].seller);
    }
   

    function _seteFILAddress(address _efilAddress)public{
        require(_efilAddress != address(0),"cant be zero");
        eFILAddress = _efilAddress;
    }
    
    
    function _safeTransfer( address owner,address to, uint value) private {
        (bool success, bytes memory data) = eFILAddress.call(abi.encodeWithSelector(SELECTOR, owner,to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'NFTMarket: TRANSFER_FAILED');
    }
    
    
    //计算nft价值
    function computeNftValue(uint id)public returns(uint){
       NFTMachine memory nft =  NFTMachines[id];
       uint value = nft.filCount.mul(8).div(10);
       return value;
       
    } 
    
    
    //修改价格
    function resetNFTPrice(uint id, uint _price)public onlyOwnerOf(id){
        require(_price >= 0 && _price <= type(uint).max,"error price");
        NFTMachineShop[id].price = _price;
    }



    //下架nft
    function productOff(uint id)public onlyOwnerOf(id){
        require(NFTMachineShop[id].seller != address(0),"invalid nft id");
        delete NFTMachineShop[id];
        require(deleteIndex(id));

    }
    
    //获取所有商城中的NFT
    function getNFTInfoAll()public view returns (uint[] memory){
            return nftIndexMgr;
    }


    //删除nftIndex
    function deleteIndex(uint tokenID)internal returns(bool){
        for(uint i=0;i<nftIndexMgr.length;i++){
             if (nftIndexMgr[i] == tokenID){
                 nftIndexMgr[i] = nftIndexMgr[nftIndexMgr.length-1];
                 nftIndexMgr.pop();
                 return true;
             }
         }
        return false;

    }
    
    function getLen()internal returns(uint){
        return nftIndexMgr.length;
    }
}