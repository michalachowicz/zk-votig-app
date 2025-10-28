// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./verifier.sol";

contract Voting {

    address public owner;
    struct  Round {
        uint startTime;
        uint endTime;
        bytes32 merkleRoot;
        bytes32[] options;
    }
    Groth16Verifier immutable verifier;
    uint public roundsCount = 0;
    mapping ( uint => Round) public roundDetails;
    mapping (uint => mapping(bytes32 => uint)) public votes;
    mapping (uint => uint) public totalVotes;
    mapping (uint => mapping(bytes32 => bool)) public hasVoted;
    mapping ( uint => mapping(bytes32 => bool)) public isOption;


    constructor(address _verifier) {
        owner = msg.sender;
        verifier = Groth16Verifier(_verifier);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Address is not the owner!");
        _;
    }   

    function changeOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function addRound(uint startTime, uint endTime, bytes32 merkleRoot, bytes32[] calldata options) external onlyOwner {
        require (startTime > block.timestamp, "Start time has to be greater than current time!");
        require (endTime > startTime, "End time has to be greater than start time!");
        require (options.length > 0, "At least one option is required!");

        roundDetails[roundsCount] = Round(startTime, endTime, merkleRoot, options);
        for (uint i = 0; i < options.length; i++) {
            isOption[roundsCount][options[i]] = true;
        }
        roundsCount++;
    }

    function vote(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, bytes32 _nullifier, bytes32 _vote, uint _roundId) external{
        require(block.timestamp >= roundDetails[_roundId].startTime, "Voting has not started yet!");
        require(block.timestamp <= roundDetails[_roundId].endTime, "Voting has ended!");
        require(hasVoted[_roundId][_nullifier] == false, "Already voted!");
        require(isOption[_roundId][_vote] == true, "Invalid option!");
        uint[4] memory pub = [uint(roundDetails[_roundId].merkleRoot), uint(_nullifier), uint(_vote), _roundId];
        require(verifier.verifyProof(_pA, _pB, _pC, pub), "Invalid proof!");
        votes[_roundId][_vote]++;
        totalVotes[_roundId]++;
        hasVoted[_roundId][_nullifier] = true;
    }

    function getOptions(uint _roundId) external view returns (bytes32[] memory) {
        return roundDetails[_roundId].options;
    }
}