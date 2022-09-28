// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
//0x55F5542BFAfeae62E4421761cdaCEdCE95e1b39c 
contract LotteryV2 is Ownable{
  
    // 0或1
    enum Result {A, B}
    // enum Result {WIN}
    // 0 未开始 1，正在进行 2.结算上一场
    enum  Status { NotStarted, Running, Pending}
    //记录每个地址押注的金额
    mapping(uint => mapping(address => uint))public  bets;
    //记录每局游戏 正反方 押注者的地址
    mapping(uint => mapping(Result => address[]) ) public  betAddrs;
    //记录 每局游戏 正反方 总投注额
    mapping(uint => mapping(Result => uint)) public  betResultVals;
    //记录每场得结果
    mapping(uint => Result) public results;
    //记录每场的游戏进度
    mapping(uint=> Status) public statuses;
    //记录每局的开始时间
    mapping(uint => uint ) public startBlockId;
    //记录每局的结束时间
    mapping(uint => uint ) public endBlockId;
    //记录每局的发起者地址
    mapping(uint => address) public starters;
    //每局合约所有人的分红比例

    mapping(uint => string) public topics;
    uint8 public ownerProportion ;
    //每局发起人的 分红比例
    uint public starterProportion;
    //每局的id
    uint public id;
    //随机填充数
    string  nonce;
    //该局游戏时间错过
    error NotInRange();
    //小于最小押注额
    error LessMinBet();
    //该局游戏未开始
    error NotStarted();
    event Checkout(uint id);
    event Start(uint id ,address starter);
    uint maxblocks = 6 * 24 * 7;
    uint minBetVal = 10000;

    //@_blocks: 设定几个区块时间
    //@ _minBetVal: 最小投注额 
    constructor(uint8 _ownerProportion, uint _starterProportion) {
        ownerProportion = _ownerProportion;
        starterProportion = _starterProportion;
    }

    //设置随机数
    function setNonce( string calldata  _nonce) external onlyOwner {
        nonce = _nonce;
    }

    //开始
    function start(uint _blocks
     ,string calldata _topic) external {
        require(5 <_blocks
         && _blocks
        < maxblocks
        );
        //require( _topic.length <30);
        id += 1;
        startBlockId[id] = block.number;
        endBlockId[id] = startBlockId[id] + _blocks;    
        statuses[id] = Status.Running;
        starters[id] = msg.sender;
        topics[id] = _topic;
        emit Start(id, msg.sender);
    }
    
    //投注
    function bet(uint _id, Result _result) external payable {
        if(statuses[_id] != Status.Running ||block.number > endBlockId[id] ){
          revert NotInRange();
        }

        if (msg.value < minBetVal){
          revert  LessMinBet();
        } 

        bets[id][msg.sender] = msg.value;
        betAddrs[id][_result].push(msg.sender);
        betResultVals[id][_result] += msg.value;
    }   

    // 获取开奖结果
    function _getRes() private view returns(Result ){
      return  Result(uint(keccak256(abi.encodePacked(block.number,address(this).balance, nonce, msg.sender))) % 2);
    }

    function checkout(uint _id) public  {
        if(statuses[_id] != Status.Running || block.number < endBlockId[_id]){
           revert NotInRange();
        }

        statuses[_id] = Status.Pending;
        Result result = _getRes();
        results[_id] = result;
        uint winBetVal = betResultVals[_id][result];

        // 输方总投注额的 扣除发起人和 合约作者 抽成的作为分红
        uint betVal = winBetVal +  betResultVals[_id][Result(1- uint(result))];
        uint shares = betVal * (100 - starterProportion -ownerProportion) / 100;
        address[] memory  addrs = betAddrs[_id][result];
        uint addrLength = addrs.length;
        mapping (address => uint) storage  addrBet = bets[_id];
        for(uint i=0; i< addrLength; i++){ 
            
            address addr = addrs[i];
            //按投注比例分红
            uint share = addrBet[addr] * shares / winBetVal;
           
            payable(addr).transfer(share);
           
        }
        //按比例给发起人分红
        payable(starters[_id]).transfer(betVal * starterProportion / 100);
        //结余的返回给 owner
        payable(owner()).transfer(betVal * ownerProportion /100);
        emit Checkout(_id);
    }


}