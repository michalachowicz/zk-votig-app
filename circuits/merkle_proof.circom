pragma circom 2.0.0;

include "poseidon.circom";

template OneLevelVerifier() {

    signal input currentHash;
    signal input sibling;
    signal input side;

    signal output root;

    component hasher = Poseidon(2);

    side * (side-1) === 0;

    signal l0;
    signal r0;
    signal l1;
    signal r1;
    l0 <== (1-side) * currentHash;
    r0 <== side * sibling;
    hasher.inputs[0] <== l0 + r0;
    l1 <== side * currentHash;
    r1 <== (1 - side) * sibling;
    hasher.inputs[1] <== l1 + r1;

    root <== hasher.out;
}

template VerifyMerkleTree(levels) {
    signal input secret;
    signal input siblings[levels];
    signal input sides[levels];

    signal output root;

    component hasher = Poseidon(1);
    hasher.inputs[0] <== secret;

    component h[levels];
    signal currentHash[levels+1];

    currentHash[0] <== hasher.out;

    for (var i = 0; i < levels; i++){
        h[i] = OneLevelVerifier();
        h[i].currentHash <== currentHash[i];
        h[i].sibling <== siblings[i];
        h[i].side <== sides[i];
        currentHash[i+1] <== h[i].root;
    }
    root <== currentHash[levels];
}

component main = VerifyMerkleTree(3); 