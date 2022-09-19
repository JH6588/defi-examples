// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";


interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

}


contract MyERC20 is Ownable ,IERC20{
    string _name;
    string _symbol;
    uint8 _decimals;
    uint _totalSupply;
    mapping(address => uint ) balances;
    mapping(address => mapping(address => uint) ) allowances;
    //记录已经approved 但是没用transferd 统计
    mapping(address => uint) public untransfered;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Mint(address indexed _owner, uint256 _value);

    // 预留余额 保证approved可兑现
    modifier checkApprovedNotTransfered(address _spender, uint256 _value){
        require(untransfered[msg.sender] + _value <= balances[msg.sender],"checkApprovedNotTransfered not meet");
        _;
    }

    constructor( string memory name_, string memory symbol_ ,uint8 decimals_, uint _value) {
        _symbol = symbol_;
        _name= name_;
        _decimals = decimals_;
        _mint(msg.sender, _value);
    }

    function _mint(address _addr , uint _value) public onlyOwner{
        _totalSupply += _value;
        balances[_addr] += _value;
        emit Mint(_addr,  _value);
    }

    function name() external view override returns (string memory){
        return _name;
    }

    function symbol() external view override returns (string memory){
        return _symbol;
    }

    function decimals() external view override returns (uint8){
        return _decimals;
    }
     
    function totalSupply() external view  override returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address _addr) external view override  returns (uint256 balance){
        return balances[_addr];
    }

    function transfer(address _to, uint256 _value) external override checkApprovedNotTransfered(msg.sender,  _value)  returns (bool success){
       
        require(balances[msg.sender] >= _value ,"balance is not enought"); 
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external override returns (bool success){
        require(balances[_from] >= _value ,"from balance is not enought");
        //require(untransfered[_from] >= _value, "untransfered balance is not enough");
        require(allowances[_from][_to] >= _value, "allowance is not enough");
        balances[_to]  += _value;
        balances[_from] -= _value;
        untransfered[_from] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external override returns (bool success){
        require(_value > 0 ,"value must bigger than 0");
        _approve(_spender, _value);
        return true;

    }

    function _approve(address _spender, uint256 _value) internal checkApprovedNotTransfered(_spender,  _value){
        require(msg.sender != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        allowances[msg.sender][_spender] += _value;
        untransfered[msg.sender] += _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function resetApprove(address _spender, uint256 _value) public returns (bool success){
        untransfered[msg.sender] -=allowances[msg.sender][_spender];
        allowances[msg.sender][_spender] = 0;
        if(_value > 0){
            _approve(_spender, _value);
        }
        return true;       
    }

    function allowance(address _owner, address _spender) external view override returns (uint256 remaining){
        return allowances[_owner][_spender];
    }

}