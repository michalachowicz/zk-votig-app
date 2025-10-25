pragma circom 2.0.0;

include "poseidon.circom";

template VerifyHash(pub) {

    // Declaration of signals.
    signal input secret;

    signal output hash;


    component hasher = Poseidon(2);
    
    hasher.inputs[0] <== secret;
    hasher.inputs[1] <== pub;
    hash <== hasher.out;
}

component main = VerifyHash(100); 