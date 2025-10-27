pragma circom 2.0.0;

include "poseidon.circom";

template VerifyMerkleTree() {

    signal input secret;
    signal input sibling;
    signal input side;

    signal output root;

    component hash = Poseidon(1);
    component hasher = Poseidon(2);

    side * (side-1) === 0;

    hash.inputs[0] <== secret;

    signal l;
    signal r0;
    signal l1;
    signal r1;
    l0 <== (1-side) * hash.out;
    r0 <== side * sibling;
    hasher.inputs[0] <== l0 + r0;
    l1 <== side * hash.out;
    r1 <== (1 - side) * sibling;
    hasher.inputs[1] <== l1 + r1;

    root <== hasher.out;
}

component main = VerifyMerkleTree(); 