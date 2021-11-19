pragma solidity ^0.7.6;


// 预言机接口

interface Ioracle{
    event sendMsg(uint indexed id);
    function getValue(uint id)external returns (uint);
    function updated(uint id, uint value)external;
    
}

contract Oracle is Ioracle{
    uint public NFTvalue;
    mapping(uint=> Req) public requests;
    uint public reqId ;
    struct Req{
        uint reqId;
        bool status;
    }

    function getValue(uint id)public override returns (uint){
        Req memory req = Req(reqId++,false);
        emit sendMsg(id);
    }

    function updated(uint id, uint value)public override{
        require(requests[id].status == false);
        
        NFTvalue = value;
        
        delete requests[id];
    }
    
}