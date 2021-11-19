//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../library/safemath.sol";
import "./ownable.sol";


contract NFTMachineFactory is Ownable{
   string public name ;
    
    using SafeMath for uint256;
    address public admin; 

    NFTMachine[] public NFTMachines;


    mapping (uint => address) public NFTMachineToOwner;

    mapping (address => uint) ownerNFTMachineCount;

    uint public NFTMachineCount = 0;
    
    mapping(address=>NFTCreateRequest[]) public createPendingQueue;
    

    event NewNFTMachine(uint id);

    
    //请求
    struct NFTCreateRequest{

        NFTMachine nft;
    
        
        bool onlyOnce;

    }
   
   
    //NFT基本属性
    struct NFTMachine{
        //产品ID
        string ID;
        //所属矿池
        string poolName;
        //铸造时间
        uint timeStamp;
        //当前算力
        uint power;
        //当前质押币数量
        uint filCount;
        //上次交易时间
        uint lastSellTimeStamp;
        //产品到期时间
        uint expire;
        //流转次数
        uint counts;
    }

    //创建NFT
    function createNFTMachine(uint index,address onwer) checkMustBeTrue(msg.sender,onwer,index) public {
        
    
        NFTMachines.push(createPendingQueue[onwer][index].nft) ;
        
        uint id = NFTMachines.length -1;

        NFTMachineToOwner[id] = onwer;

        ownerNFTMachineCount[onwer] = ownerNFTMachineCount[onwer].add(1);

        NFTMachineCount = NFTMachineCount.add(1);

        emit NewNFTMachine(id);
  }

    
    
      //铸造请求
    function commitNFTCreateRequest(string memory _id,string memory _poolName,uint _power, uint _filCount,uint _expire)public{
        require(_expire >= block.timestamp,"_expire must be >= now");
        NFTMachine memory nft = NFTMachine(_id,_poolName,block.timestamp,_power,_filCount,0,_expire,0);
        NFTCreateRequest memory req = NFTCreateRequest(nft,true);
        createPendingQueue[msg.sender].push(req);
    }
    
    

    //权限检查
    modifier checkMustBeTrue(address caller, address owner,uint index){
        require(caller == admin && createPendingQueue[owner][index].onlyOnce == true ,"createPendingQueue status must be true");
        
        _;
        createPendingQueue[owner][index].onlyOnce = false;
        
        
    }
    

    //检查所属权
    modifier onlyOwnerOf(uint _NFTMachinesId) {
        require(msg.sender == NFTMachineToOwner[_NFTMachinesId],'NFTMachine is not yours');
        _;
  }

    //
    function getOwnerNFTMachineCount(address caller)public returns(uint){
        return ownerNFTMachineCount[caller];
    }
    
    
    function getNFTPendingReq(address _who)public view returns(NFTCreateRequest[] memory){
        if(_who == address(0)){
            return createPendingQueue[msg.sender];
        }else{
            return createPendingQueue[_who];
        }
    }
    
}