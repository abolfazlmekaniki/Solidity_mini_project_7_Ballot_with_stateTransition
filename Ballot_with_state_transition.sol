// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*  

Entity ===> Data Structure :

    1) Proposal ==> struct
    2) list of proposals ==> struct[]
    3) voter ==> struct 
    4) Voters ==> mapping(address => struct)
    5) chairperson => address

Functionality ===> function

    1) register
    2) vote
    3) count    

*/

contract Ballot{

    struct Proposal {

        uint voteCount;

    }

    Proposal[] proposals ;


    enum StateTransition {     // by this enum we can manage the event.

        Register ,
        Vote , 
        Count
    }

    StateTransition status ;


    struct Voter {

        uint vote_id;

        uint voteWeidth;

        bool voted;

    }

    mapping( address => Voter ) public voters;

    address chairPerson ;

    uint[] sameVoteCount ;

    uint startTime ;

    uint public WinnerID;

    uint public WinnerCount;



    constructor( uint8 proposalValue ){

        chairPerson = msg.sender ;

        startTime = block.timestamp;

        for(uint i=0 ; i<proposalValue ; i++){

            proposals.push(Proposal({voteCount:0}));

        }

        voters[chairPerson].voteWeidth=2;

        status = StateTransition.Register;

    }


    modifier onlyowner(){

        require(msg.sender==chairPerson , "you are not owner !");  // only owner can register new voter !
        _;

    }


    modifier once_register(address newVoter){

            require(newVoter != msg.sender , "owner was registerd already !");  // owner can not register twice !
            _;
    }


    modifier not_vote_before(address newVoter){

         require( voters[newVoter].voted == false , "new voter must not vote already !");  // register only new voter  !!
         _;
    }

    modifier RegisterTime() {

        require(status==StateTransition.Register , "it is not register time");
        _;

    }

    modifier updateStatus() {

        if(block.timestamp-startTime < 30){

            status=StateTransition.Register;  // 30 seconds to register voters after deploy contract
        }

        else if (block.timestamp-startTime < 60){

            status=StateTransition.Vote; // 30-60 seconds after deploy is time of voting.
        }

        else if (block.timestamp-startTime < 60){

            status=StateTransition.Count; // 60-90 seconds after deploy is time of counting.
        }
        _;

    }


    function register(address newVoter) public updateStatus RegisterTime onlyowner once_register(newVoter) not_vote_before(newVoter)  {

        voters[newVoter].voteWeidth = 1;  // register complited !

    }


    modifier not_voted_before(){

        require( voters[msg.sender].voted == false , " you  voted already !!");  // voter must not vote already !
        _;
    }

    modifier registerd_before(){

        require( voters[msg.sender].voteWeidth !=0 , " you have not registerd yet !"); // voter must have registerd already !
        _;

    }

    
    modifier VotingTime() {

        require(status==StateTransition.Vote , "it is not vote time");
        _;

    }


    function vote_(uint voteId) public updateStatus VotingTime not_voted_before registerd_before  {

        proposals[voteId].voteCount += voters[msg.sender].voteWeidth ; 

        voters[msg.sender].voted = true ;

        voters[msg.sender].vote_id = voteId ;

    }


    modifier CountTime() {

        require(status==StateTransition.Count , "it is not count time");
        _;

    }


    function count() public  updateStatus CountTime onlyowner {



        // sameVoteCount.push(proposals[0].voteCount);

        for(uint i = 0 ; i < proposals.length ; i++){

                if(proposals[i].voteCount > WinnerCount){

                    WinnerCount = proposals[i].voteCount;

                    WinnerID = i ;

                    while(sameVoteCount.length !=0){

                        sameVoteCount.pop();

                    }

                    sameVoteCount.push(i);

                }

                else if (proposals[i].voteCount == WinnerCount){
                    
                        sameVoteCount.push(i);

                }



        }

        WinnerID = sameVoteCount[uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % sameVoteCount.length] ;
        WinnerCount = proposals[WinnerID].voteCount ;

    }

}
