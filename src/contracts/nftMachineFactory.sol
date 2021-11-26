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

    //拥有的NFTtokenid
    mapping(address=>uint[]) public NFTOfOwnerInfos;

    mapping(uint => address) public NFTMachineToOwner;

    mapping(address => uint) ownerNFTMachineCount;

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

        AddTokenIdToInfoMgr(id,onwer);

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
    
    //添加NFTtoken至用户信息
    function AddTokenIdToInfoMgr(uint id, address adds)internal returns (bool){
        require(adds != address(0),"adds cant be zero");
        NFTOfOwnerInfos[adds].push(id);
    }

    //删除NFTtoken至用户信息
    function delTokenIdToInfoMgr(uint id, address adds)internal returns (bool){
        require(adds != address(0),"adds cant be zero");
        for(uint i=0;i<NFTOfOwnerInfos[adds].length;i++){
            if (NFTOfOwnerInfos[adds][i] == id){
                NFTOfOwnerInfos[adds][i] = NFTOfOwnerInfos[adds][NFTOfOwnerInfos[adds].length-1];
                NFTOfOwnerInfos[adds].pop();
                return true;
            }
        }
        return false;
        
    }



    //查询用户的所有NFT otkenid
    function getTokenIdToInfoMgrAll(address adds)public view returns(uint[] memory){
        require(adds != address(0),"adds cant be zero");
        return NFTOfOwnerInfos[adds];
    }
}