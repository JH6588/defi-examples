// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Poll is Ownable{
    //候选人数
    uint8 public candidates;
    //总投票数限制
    uint public turnout;
    //投票时间
    uint public duration;
    bool public started;
    bool public ended;
    uint public endTime;
    //投票数
    uint public votedNum;
    //记录投票人投给那位候选人
    mapping(address => uint8) public votedMap;
    //记录每位候选人得票数
    mapping(uint8 => uint) scoreMap;
    //当前最高票 目标索引
    uint8 public highestCandidate;
    //当前最高票 得票数
    uint public highestScore;
    event Started();
    event Ended();

    constructor(uint8 _candidates, uint _turnout, uint _duration){
        candidates = _candidates;
        turnout = _turnout;
        duration = _duration;
    }

    function start() external onlyOwner{
        require(!started, "already started");
        require(!ended, "already ended");
        started = true;
        endTime = block.timestamp + duration;
        emit Started();
    }

    function end() public{       
       require(started,"not started");
       require(!ended, "already ended");
       if (block.timestamp > endTime || votedNum == turnout){
            ended = true;
            emit Ended();
        }
    }  
    
    function vote(uint8 candidateIndex) external {
        
        require(! ended, "vote ,already ended");
        require(block.timestamp < endTime && votedNum <  turnout,"meet ended condition");
        require(0< candidateIndex && candidateIndex <= candidates,"0< candidateIndex < candidates");
        require(votedMap[msg.sender] ==0 ,"you have voted already");
        
        votedMap[msg.sender] = candidateIndex;
        scoreMap[candidateIndex] += 1;
        if (scoreMap[candidateIndex] > highestScore){
            highestCandidate = candidateIndex;
            highestScore = scoreMap[candidateIndex];
        }
        votedNum += 1;
    }

    function getResult() external view returns (uint8) {
        require(ended);
        return highestCandidate;
    }

    function destory() external onlyOwner {
        selfdestruct(payable (msg.sender));
    }
}