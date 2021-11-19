pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;
import "./safemath.sol";

contract Test{
   
   struct Info{
       
       uint256 age;
   }
    
    function getTime()public  returns (Info[] memory){
     
      Info[] memory infoms = new Info[](2);
       
        return infoms;
    }
    
}