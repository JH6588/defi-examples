// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lottery is Ownable{
    //单场的持续时间
    uint8 public duration;
    // 0或1
    enum Result {A, B}
    //最近一场的开奖结果
    Result public lastResult;
    //最小投注额
    uint public minBetVal;
    //单场的游戏状态
    enum  Status { NotStarted, Running, Pending}
    Status public status;
    //投注地址 =>投注额
    mapping(address => uint) bets;
    mapping(Result => address[] ) betAddrs;
    //选项 => 该项总投注额 
    mapping(Result => uint) betVals;
    bool public started;
    uint public startTime;
    uint public endTime;
    //场次
    uint public times;
    //填充数
    string  nonce;
    error NotInRange();
    error LessMinBet();
    error NotStarted();
    event Start();
    event RunningStatus();
    
    modifier checkStarted() {
      if (!started){
        revert NotStarted();
      }
      _;
    }

    constructor(uint8 _duration, uint _minBetVal) {
        duration = _duration;
        minBetVal = _minBetVal;
    }
    //设置填充数
    function setNonce( string calldata  _nonce) external onlyOwner {
        nonce = _nonce;
    }

    function start() external onlyOwner{
        started = true;
        startTime = block.timestamp;
        endTime = startTime + duration;
        status = Status.Running;
        times = 1;
        emit Start();
    }
    //下注
    function bet(Result result) external payable checkStarted  {
        if(status != Status.Running ||block.timestamp > endTime ){
          revert NotInRange();
        }

        if (msg.value < minBetVal){
          revert  LessMinBet();
        } 

        bets[msg.sender] = msg.value;
        betAddrs[result].push(msg.sender);
        betVals[result] += msg.value;
    }   
    //开奖分红
    function checkout() public checkStarted {
        if(status != Status.Running){
           revert NotInRange();
        }
      
        if (block.timestamp >endTime){
                status = Status.Pending;
                //获取开奖结果
                lastResult = Result(uint(keccak256(abi.encodePacked(block.timestamp,address(this).balance, nonce, msg.sender))) % 2);
                uint winBetVal = betVals[lastResult];
                //输方总投注额
                uint lostBetVal = betVals[Result(1- uint(lastResult))];
                //合约扣5% 
                uint shares = lostBetVal * 95 % 100;
                for(uint i=0 ; i< betAddrs[lastResult].length ;i++){ 
                   
                    address addr = betAddrs[lastResult][i];
                    //根据投注比例分红
                    uint share = bets[addr] /winBetVal * shares;
                    payable(addr).transfer(share + bets[addr]);
                }
                payable(owner()).transfer(address(this).balance);
                status = Status.Running;
                times += 1;
                emit RunningStatus();
            }
    }
}