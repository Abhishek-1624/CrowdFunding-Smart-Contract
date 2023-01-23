// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.5;

contract CrowdFunding{
    mapping(address => uint) public contributors;
    address public admin;
    uint public noOfContributors;
    uint public minimumContribution;
    uint public deadline;//This will be the timestamp of the block
    uint public goal;
    uint public raisedAmount;
    struct Request{
        string description;
        address payable recepient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }
    //For a campaign one can create more than one spending Request
    mapping(uint => Request) public requests;
    //It is neccessary because a mapping does not use or increment indxes automatically like an array
    uint public numRequests;

    constructor(uint _goal , uint _deadline){
        //In the constructor we need to mention the goal and the dealine of the crowdfunding 
        //We need to specify all the neccessary stuff in the constructor
        goal = _goal;
        deadline = block.timestamp + _deadline;
        //Here block.timestamp is the current time and we are addding _dealine in seconds to mention when
        //the crowdfunding will end,if we need it to end in an hour we add 3600secs
        minimumContribution = 100 wei;
        admin = msg.sender;
    }
    //We need to create a function so that users can contribute to the crowdfunding
    function contribute() public payable{
        require(block.timestamp < deadline,"The deadline has passed");
        require(msg.value >= minimumContribution,"Minimum Contribution not met");

        if(contributors[msg.sender] == 0){
            //This required to check if the contribution is made for the first time
            noOfContributors++;
        }

        contributors[msg.sender] += msg.value; //This is the total amount of wei sent by that address
        raisedAmount += msg.value; //Total raised amount has been incremented
    }

    //We need to declare the receive function to get ETH
    receive() payable external{
        contribute();
    }

    //This is function is to get the total balance of the contract
    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    /*If the goal is not reached within the deadline the campaign cannot be execuded in that case 
    the users can ask for a refund*/
    function getRefund() public{
        require(block.timestamp > deadline && raisedAmount < goal);
        require(contributors[msg.sender] > 0);//This is to check the current has sent money before
        
        address payable recepient = payable(msg.sender);
        uint value = contributors[msg.sender];
        recepient.transfer(value);

        //Now we are setting the value sent by the contributor to zero so that they cannot ask for refund more than once
        contributors[msg.sender] = 0;
    }
    //We are creating a function modifier OnlyAdmin
    modifier onlyAdmin(){
        require(msg.sender == admin,"Only admin can call this function");
        _;
    }
    //Now we need to create a function to intialise a spending request
    function createRequest(string memory _description, address payable _recepient, uint _value) public onlyAdmin{
        Request storage newRequest = requests[numRequests];
        numRequests++;

        newRequest.description = _description;
        newRequest.recepient = _recepient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }
    //Lets create a voting function which will called by contributors
    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender] > 0,"You must be contributor to vote");
        Request storage thisRequest = requests[_requestNo];

        require(thisRequest.voters[msg.sender] == false,"You have already voted !!");
        thisRequest.voters[msg.sender] = true; //This means user has already voted
        thisRequest.noOfVoters++;
    }
    //Now we need to create a makePayment function that will be called by the admin to transfer the money of a spending 
    //request to a vendor this can only be called when admin creates a spending request and contributors vote for it
    function makePayment(uint _requestNo) public onlyAdmin{
        require(raisedAmount >= goal);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false,"The request has been completed");
        require(thisRequest.noOfVoters > noOfContributors/2);
        thisRequest.recepient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}

