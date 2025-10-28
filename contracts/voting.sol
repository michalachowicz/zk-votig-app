// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./verifier.sol";

contract Voting {

    address public owner;
    struct  Round {
        uint commitmentStartTime;
        uint commitmentEndTime;
        uint revealEndTime;
        bytes32 merkleRoot;
        bytes32[] options;
    }
    Groth16Verifier immutable verifier;
    uint public roundsCount = 0;
    mapping ( uint => Round) public roundDetails;
    mapping (uint => mapping(bytes32 => uint)) public votes;
    mapping (uint => uint) public totalVotes;
    mapping (uint => uint) public totalRevealedVotes;
    mapping (uint => mapping(bytes32 => bool)) public hasVoted;
    mapping ( uint => mapping(bytes32 => bool)) public isOption;
    mapping (uint => mapping(bytes32 => bool)) public commitments;
    uint constant P = 21888242871839275222246405745257275088548364400416034343698204186575808495617;


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

    function addRound(uint commitmentStartTime, uint commitmentEndTime, uint revealEndTime, bytes32 merkleRoot, bytes32[] calldata options) external onlyOwner {
        require (commitmentStartTime > block.timestamp, "Commitment start time has to be greater than current time!");
        require (commitmentEndTime > commitmentStartTime, "Commitment end time has to be greater than start time!");
        require (revealEndTime > commitmentEndTime, "Reveal end time has to be greater than commitment end time!");
        require (options.length > 0, "At least one option is required!");

        roundDetails[roundsCount] = Round(commitmentStartTime, commitmentEndTime, revealEndTime, merkleRoot, options);
        for (uint i = 0; i < options.length; i++) {
            isOption[roundsCount][options[i]] = true;
        }
        roundsCount++;
    }

    function commit(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, bytes32 _nullifier, bytes32 _commit, uint _roundId) external{
        require(_roundId  < roundsCount, "Round does not exist!");
        require(block.timestamp >= roundDetails[_roundId].commitmentStartTime, "Committing has not started yet!");
        require(block.timestamp <= roundDetails[_roundId].commitmentEndTime, "Committing has ended!");
        require(hasVoted[_roundId][_nullifier] == false, "Already commited!");
        uint[4] memory pub = [uint(roundDetails[_roundId].merkleRoot), uint(_nullifier), uint(_commit), _roundId];
        require(verifier.verifyProof(_pA, _pB, _pC, pub), "Invalid proof!");
        commitments[_roundId][_commit] = true;
        totalVotes[_roundId]++;
        hasVoted[_roundId][_nullifier] = true;
    }

    function reveal(bytes32 _commit, bytes32 _option, bytes32 _nullifier, uint _roundId, bytes32 _salt) external {
        require(_roundId < roundsCount, "Round does not exist!");
        require(block.timestamp > roundDetails[_roundId].commitmentEndTime, "Revealing has not started yet!");
        require(block.timestamp <= roundDetails[_roundId].revealEndTime, "Revealing has ended!");
        require(commitments[_roundId][_commit], "Commitment not found or already revealed!");
        require(isOption[_roundId][_option], "Invalid option!");
        //The circom circuit operates in the BN254 field (mod P)
        //Therefore the value of the public output may be different from the input value if it is >= P
        //During proof generation keccak hash is used as the circuit input
        //In the commit phase user provides value reduced to the field of P - keccak(option, nullifier, roundId, salt) % P
        require(uint(_commit) == uint(keccak256(abi.encode(_option, _nullifier, _roundId, _salt))) % P, "Invalid commitment!");
        votes[_roundId][_option]++;
        commitments[_roundId][_commit] = false;
        totalRevealedVotes[_roundId]++;        
    }

    function getOptions(uint _roundId) external view returns (bytes32[] memory) {
        return roundDetails[_roundId].options;
    }
}