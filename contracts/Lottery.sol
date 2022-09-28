// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

//0x55F5542BFAfeae62E4421761cdaCEdCE95e1b39c
contract Lottery is Ownable {
    uint8 public duration;
    // 0或1
    enum Result {
        A,
        B
    }
    Result public lastResult;
    uint public minBetVal;
    // enum Result {WIN}
    // 0 未开始 1，正在进行 2.等待开启下一局q
    enum Status {
        NotStarted,
        Running,
        Pending
    }
    Status public status;
    mapping(uint => mapping(address => uint)) public bets;
    mapping(uint => mapping(Result => address[])) public betAddrs;
    mapping(uint => mapping(Result => uint)) public betVals;
    uint public startTime;
    uint public endTime;
    uint public times;
    string nonce;
    error NotInRange();
    error LessMinBet();
    error NotStarted();
    event Start(uint indexed times);
    event Checkout(uint indexed times);

    //@_duration: 每局的时长
    //@ _minBetVal: 最小投注额
    constructor(uint8 _duration, uint _minBetVal) {
        duration = _duration;
        minBetVal = _minBetVal;
    }

    //设置随机数
    function setNonce(string calldata _nonce) external onlyOwner {
        nonce = _nonce;
    }

    //开始
    function start() external onlyOwner {
        startTime = block.timestamp;
        endTime = startTime + duration;
        status = Status.Running;
        times += 1;
        emit Start(times);
    }

    //投注
    function bet(Result result) external payable {
        if (status != Status.Running || block.timestamp > endTime) {
            revert NotInRange();
        }

        if (msg.value < minBetVal) {
            revert LessMinBet();
        }

        bets[times][msg.sender] = msg.value;
        betAddrs[times][result].push(msg.sender);
        betVals[times][result] += msg.value;
    }

    // 获取开奖结果
    function _getRes() private view returns (Result) {
        return
            Result(
                uint(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            address(this).balance,
                            nonce,
                            msg.sender
                        )
                    )
                ) % 2
            );
    }

    function checkout() external {
        if (status != Status.Running || block.timestamp < endTime) {
            revert NotInRange();
        }
        status = Status.Pending;
        lastResult = _getRes();
        uint winBetVal = betVals[times][lastResult];
        uint lostBetVal = betVals[times][Result(1 - uint(lastResult))];
        // 输方总投注额的 95%的作为分红
        uint shares = (lostBetVal * 95) / 100;
        address[] memory resultAddrs = betAddrs[times][lastResult];
        for (uint i = 0; i < resultAddrs.length; i++) {
            address addr = resultAddrs[i];
            //按投注比例分红
            uint share = (bets[times][addr] * shares) / winBetVal;
            payable(addr).transfer(share + bets[times][addr]);
        }
        payable(owner()).transfer(address(this).balance);
        emit Checkout(times);
    }

    function destory() external onlyOwner {
        require(status == Status.Pending);
        selfdestruct(payable(owner()));
    }
}
