const { ethers } = require("hardhat");

describe("test poll", function(){
    let owner, account1, account2, account3;
    let poll;
   
    before("ready ... ",
        async() => {
            [owner, account1, account2, account3] = await ethers.getSigners();
            // account1 = account1.address;
            // account2 = account2.address;  
            let factory = await ethers.getContractFactory("Poll");
            poll = await factory.deploy(2,3,1000);
        }
    );

    it("start ...", async()=>{
        poll.start()
        console.log("started is " + await poll.started());
    });
    async function vote(){
     
            await poll.vote(1);
            await poll.connect(account1).vote(2);
            await poll.connect(account2).vote(1);
            await poll.connect(account3).vote(2);
    }


    async function finish(){
        vote().catch(async (error) => {
            if(error.message.indexOf("meet ended")!=-1){
            console.log("meet end condition");
            await poll.end();
            // await poll.on("Ended" ,async ()=>{
                console.log("the result is " + await poll.getResult());
            // })   
            }
          
        }); } 
    it("vote ...", finish
        )

    
    });
    



