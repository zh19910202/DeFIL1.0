// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./safemath.sol";

contract FreeMarket{
    
    using SafeMath for uint256;
    

    
    //nft
    address private nftAddress;

    //efil
    address public eFILAddress;
    
    //查看所属权
    bytes4 private constant SELECTOR1 = bytes4(keccak256(bytes('getOwnerNFTMachineCount(address)')));
    bytes4 private constant SELECTOR2 = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    bytes4 private constant SELECTOR3 = bytes4(keccak256(bytes('takeOwnership(uint256)')));
    bytes4 private constant SELECTOR4 = bytes4(keccak256(bytes('ownerOf(uint256)')));
    bytes4 private constant SELECTOR5 = bytes4(keccak256(bytes('transfer(address,uint256)')));

    //admin
    address public owner;

    //借贷需求信息管理
    mapping(bytes4=>Info) public borrowInfo;

    //借贷需求信息管理索引管理
    bytes4[] internal borrowInfoIndex;

    


    constructor(){
        owner = msg.sender;
    }
    
  

    //订单状态
    enum Status {
        TX_PENDING,  //未匹配
        SUCCESS_AND_WAITREPAY  //匹配成功,等待还款
        
        }


    //需求信息
    struct Info{    
        address from;   //出借人
        address to;     //借款人  
        uint[]  certificates; //抵押物
        uint256 timestamp;
        uint256 money;    //借款额度
        uint256 time; //借款期限
        uint256 interestRate;  //借款利率
        Status status; //状态
    }

    //权限检查
    modifier mustAdmin(){
        require(owner == msg.sender,"must be onwer");
        _;
    }




    //需要确认是否有nft
    modifier hasRight(uint[] memory ids){
        require(getOwnerOfCount(msg.sender) > 0 && ids.length >0,"at last one of nft");
        for(uint i=0;i<ids.length;i++){
           address adds = _ownerOf(ids[i]) ;
           require(adds == msg.sender,"Must be from the same addresss 1");
        }    
        _;
    }

    //获取nft的归属者

    function getOwnerOfCount(address _adds)public returns (uint){
        (bool success, bytes memory data) = nftAddress.call(abi.encodeWithSelector(SELECTOR1,_adds));
        require(success && data.length !=0, 'NFTMarket: INVALID ID ');
        return abi.decode(data, (uint));
    }

    //设置nft地址
    function _setNFTAddress(address _adds)public{
        require(_adds != address(0),"cant be zero");
        nftAddress = _adds;
    }
    
     //设置efil地址
    function _seteFILAddress(address _adds)public{
        require(_adds != address(0),"cant be zero");
        eFILAddress = _adds;
    }
    

    //发布借贷需求，
    function publicBorrowMessage(uint[] memory ids,uint _money,uint _time,uint _interestRate)public hasRight(ids)returns(bool){
        return createNewMes(address(0),msg.sender,ids,_money,_time,_interestRate);
    }

    //发布放贷需求
     function publicLendMessage(uint _money,uint _time,uint _interestRate)public returns(bool){
         uint[] memory ids  = new uint[](0);
        
        return createNewMes( msg.sender,address(0),ids,_money, _time, _interestRate);
    }



    //借进
    //资格审查
    //
    function borrow(bytes4 BorrowInfoid)public  returns (bool){
        require(borrowInfo[BorrowInfoid].status ==Status.TX_PENDING && isExist(BorrowInfoid),"");
        borrowInfo[BorrowInfoid].to = msg.sender;
        uint[] memory lists = borrowInfo[BorrowInfoid].certificates;
        
        for(uint i=0;i<lists.length;i++){
           address adds = _ownerOf(lists[i]) ;
           require(adds == msg.sender,"Must be from the same addresss ");
        }
        
        makeTransaction(BorrowInfoid);
        
        return true;
    }

    //借出
    function lend(bytes4 BorrowInfoid )public returns (Info memory){
        require(borrowInfo[BorrowInfoid].status ==Status.TX_PENDING && isExist(BorrowInfoid),"");
        borrowInfo[BorrowInfoid].from = msg.sender;
        return makeTransaction(BorrowInfoid);
        
    }

    
    //查看
    function getInfoAll()public view returns (Info[] memory){
        
        Info[] memory infoms = new Info[](borrowInfoIndex.length);
        for(uint i=0;i<borrowInfoIndex.length;i++){
            infoms[0]=borrowInfo[borrowInfoIndex[i]];
        }
        return infoms;
        
      
    }


    //生成订单
    function createNewMes(address from,address to,uint[] memory ids,uint _money,uint _time,uint _interestRate) internal returns (bool){
        require(_money>0 && _time>0 &&_interestRate>0,"Conditions are not met");
        Info memory info = Info(from,to,ids,0,_money,_time,_interestRate,Status.TX_PENDING);
        bytes4 id = createNewTxid(info);
        borrowInfo[id] = info;
        borrowInfoIndex.push(id);
    }



    //促成交易 
    function makeTransaction(bytes4 BorrowInfoid)internal returns (Info memory){
        //确认该订单状态
        require(borrowInfo[BorrowInfoid].status == Status.TX_PENDING,"status must be PENDING");
        require(borrowInfo[BorrowInfoid].to !=borrowInfo[BorrowInfoid].from ,"cant be from the same address");
        //修改订单状态
        borrowInfo[BorrowInfoid].status = Status.SUCCESS_AND_WAITREPAY;
        
        borrowInfo[BorrowInfoid].timestamp = block.timestamp;
        //nft抵押到平台  
        _doNftBatchTransferIn(borrowInfo[BorrowInfoid].certificates);

        //转账
        (bool success, bytes memory data) = eFILAddress.call(abi.encodeWithSelector(SELECTOR2,borrowInfo[BorrowInfoid].from ,borrowInfo[BorrowInfoid].to, borrowInfo[BorrowInfoid].money));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'eFIL: TRANSFER_FAILED');
        
        return borrowInfo[BorrowInfoid];
      
     
    }


    
    //还款
    function repayBorrow(bytes4 BorrowInfoid ,uint repayAmount)public returns (bool){
        //本息 = 年化率 / 365 * 实际天数 * 本金 + 本金
        Info memory info = borrowInfo[BorrowInfoid];
        
        uint d = computeBorrowDays(info.timestamp,block.timestamp);
        uint principalAndInterest = (info.interestRate.div(365).mul(d).mul(info.money).add(info.money.mul(1e18))).div(1e18);
        require(repayAmount  >= principalAndInterest && info.status == Status.SUCCESS_AND_WAITREPAY,"repay back fail");
        
        //删除索引和订单
        require(deleteBorrowIndex(BorrowInfoid));
        delete borrowInfo[BorrowInfoid];
        return _doTransfer(msg.sender,info.from,principalAndInterest) && _doNftBatchTransferOut(info.certificates,info.to);
       
    }



    //清算
    function liquidationBorrow(bytes4 BorrowInfoid)public mustAdmin returns (bool){
        require(isExist(BorrowInfoid),"must be exist");
        Info memory info = borrowInfo[BorrowInfoid];
        
        require(info.time >= block.timestamp && info.status != Status.SUCCESS_AND_WAITREPAY,"status must be TX_PENDING");
        
        //删除索引和订单
        require(deleteBorrowIndex(BorrowInfoid));
        delete borrowInfo[BorrowInfoid];

        //将nft所有权转移给出借人
        return _doNftBatchTransferOut(info.certificates,info.from);
    }
    
    

    //生成订单号
    function createNewTxid(Info memory info)internal returns (bytes4 ){
      
        return bytes4(keccak256(abi.encodePacked(info.certificates)));
    }


    //efil转账
    function _doTransfer(address from,address to, uint value)internal returns (bool){
        (bool success, bytes memory data) = eFILAddress.call(abi.encodeWithSelector(SELECTOR2,from,to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'eFIL: TRANSFER_FAILED');
        return true;
    }

    //nft转进
    function _doNftTransferIn(uint id)internal returns (bool){
        (bool success, bytes memory data) = nftAddress.call(abi.encodeWithSelector(SELECTOR3, id));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'nft: TRANSFER_FAILED');
        return true;
    }
    
    function _doNftBatchTransferIn(uint[]memory ids)internal returns(bool){
        for(uint i=0;i<ids.length;i++){
            _doNftTransferIn(ids[i]);
        }
        return true;
    }


    //nft转出
    function _doNftTransferOut(uint id,address _to)internal returns (bool){
        (bool success, bytes memory data) = nftAddress.call(abi.encodeWithSelector(SELECTOR5,_to,id));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'nft: TRANSFER_FAILED');
        return true;
    }


    function _doNftBatchTransferOut(uint[]memory ids,address _to)internal returns(bool){
        for(uint i=0;i<ids.length;i++){
            _doNftTransferOut(ids[i],_to);
        }
        return true;
    }


    //检查订单是否存在
    function isExist(bytes4 id)internal returns (bool){
        Info memory info = borrowInfo[id];
        if(info.from == address(0) && info.to == address(0)){
            return false;
        }
        return true;
    }
    
    function getId(uint index)public view returns (bytes4){
        return borrowInfoIndex[index];
    }
    
    
    function _ownerOf(uint id)public returns(address){
        
       (bool success, bytes memory data) = nftAddress.call(abi.encodeWithSelector(SELECTOR4, id));
        address adds = abi.decode(data, (address)) ;
        require(success && adds != address(0), 'nft: not vaild id');
        return adds;
    }
    
    
    //添加订单号
    function addBorrowIndex(bytes4 borrowId)internal returns(uint){
        require(borrowId != "","borrowId cant be empty!");
        uint index = borrowInfoIndex.length;
        borrowInfoIndex.push(borrowId);
        return index;
        
    }


    //删除订单号
    function deleteBorrowIndex(bytes4 borrowId)internal returns (bool){
         require(borrowId != "","borrowId cant be empty!");
         for(uint i=0;i<borrowInfoIndex.length;i++){
             if (borrowInfoIndex[i] == borrowId){
                 borrowInfoIndex[i] = borrowInfoIndex[borrowInfoIndex.length-1];
                 borrowInfoIndex.pop();
                 return true;
             }
         }

        return false;
    }
    
    
    //计算实际借款天数
    function computeBorrowDays(uint start,uint end)internal returns (uint){
        require(end >= start,"end must be >= start timestamp");
        if(start == end){
            return 0;
        }else{
            if(end.sub(start) <= 86400){
                return 1;
            }
            return end.sub(start).div(86400);   
        }
    }
    
    //计算实际累计本息
    function principalAndInterest(bytes4 BorrowInfoid)public  returns(uint){

        Info memory info = borrowInfo[BorrowInfoid];
        uint d = computeBorrowDays(info.timestamp,block.timestamp);
        return (info.interestRate.div(365).mul(d).mul(info.money).add(info.money.mul(1e18))).div(1e18);
    }


}