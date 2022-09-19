const { ethers } = require("hardhat");

describe("erc20 已经approved 永远有效",function(){
    
    let erc20;
    let owner;
    let receiver1;
    let receiver2;
    
    before (
        async () =>{
            [owner, account1, account2] = await ethers.getSigners();
            owner = owner.address;
            receiver1 = account1.address;
            receiver2 = account2.address;
            let factory = await ethers.getContractFactory("MyERC20");
            erc20 = await factory.deploy("Test Tokens", "TK", 2, 10 * 10 ** 2);
            
          
        }

    );
    

    it("print..",async function(){
        console.log(`owner : ${erc20.address} \nreceiver1: ${receiver1}\nreceiver2: ${receiver2}`);
        console.log(await erc20.balanceOf(owner));
    })

    it("approved test ", async function(){
        let amount = 600
     // erc20.approve(receiver1, amount);
     // console.log("approved " + await erc20.allowance(owner, receiver1));
     // erc20.resetApprove(receiver1,0);
        console.log(await erc20.transfer(receiver2, amount));
        console.log("receiver2 balance is " + await erc20.balanceOf(receiver2));

        
    })




})