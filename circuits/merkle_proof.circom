pragma circom 2.0.0;

include "poseidon.circom";

template OneLevelVerifier() {

    signal input currentHash;
    signal input sibling;
    signal input side;

    signal output root;

    component leaf_hasher = Poseidon(2);

    side * (side-1) === 0;

    leaf_hasher.inputs[0] <== currentHash + side * (sibling - currentHash);
    leaf_hasher.inputs[1] <== sibling + side * (currentHash - sibling);

    root <== leaf_hasher.out;
}

template VerifyMerkleTree(levels) {
    signal input secret;
    signal input siblings[levels];
    signal input sides[levels];
    signal input commitment;
    signal input roundId;
    signal input nonce;

    signal output root;
    signal output nullifier;

    component nullifier_hasher = Poseidon(2);
    nullifier_hasher.inputs[0] <== secret;
    nullifier_hasher.inputs[1] <== roundId;
    nullifier <== nullifier_hasher.out;

    component leaf_hasher = Poseidon(1);
    leaf_hasher.inputs[0] <== secret;

    component h[levels];
    signal currentHash[levels+1];

    currentHash[0] <== leaf_hasher.out;

    for (var i = 0; i < levels; i++){
        h[i] = OneLevelVerifier();
        h[i].currentHash <== currentHash[i];
        h[i].sibling <== siblings[i];
        h[i].side <== sides[i];
        currentHash[i+1] <== h[i].root;
    }
    root <== currentHash[levels];
}

component main { public [commitment, roundId, nonce] } = VerifyMerkleTree(3);