pragma circom 2.0.0;

include "poseidon.circom";

template VerifyHash() {

    // Declaration of signals.
    signal input secret;

    signal output hash;

    component hasher = Poseidon(1);
    
    hasher.inputs[0] <== secret;
    hash <== hasher.out;
}

component main = VerifyHash(); 