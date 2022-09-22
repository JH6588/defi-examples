// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Grant is Ownable{
    uint public amount;
    uint public currentAmount;
    mapping(address => uint) grants;
    address[] public grantAddrs;
    uint public endTime;
    bool public success;
    
    constructor( uint _amount, uint _duration) {
        amount = _amount;
        endTime = block.timestamp + _duration;
    }

/**
 * 超时或已经成功则不准投入
 * 目标达成判断，达成后 将款项转给发起人。
 * 超过筹款目标部分则退回
 */
function support() public payable{
    require(!success ,"already successed");
    require(block.timestamp < endTime ,"overtime,please call end");
    require(currentAmount < amount ,"achieved, please call end");
    currentAmount += msg.value;
    uint diff = currentAmount - amount;
    if (diff >0 ){
        payable(msg.sender).transfer(diff);
        grants[msg.sender] =  msg.value -diff;
        payable(owner()).transfer(currentAmount);
        success = true;
       
    }else{
        grants[msg.sender] =  msg.value;
    }
}


/**
 * 废除条件：
 *  1.未筹到目标金融
 *  2.时间已超时
 * 未完成目标的话，退回
 */
function abolish() external{
    require(!success,"already successed");
    require(block.timestamp > endTime, "not overtime"); 
    for(uint i =0; i < grantAddrs.length; i++ ){
        payable(grantAddrs[i]).transfer(grants[grantAddrs[i]]);
        }
    }
   
}