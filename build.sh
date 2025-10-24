#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "no circut file given!"
    echo "Usage: ./build.sh <circuit_name> <ptau_file>"
    exit 1
fi

if [ -z "$2" ]; then
    echo "no ptau file given!"
    echo "Usage: ./build.sh <circuit_name> <ptau_file>"
    exit 1
fi

CIRCUIT=$1
PTAU=$2

mkdir -p build

echo "[1/6] Compiling ${CIRCUIT}.circom..."
circom circuits/${CIRCUIT}.circom --r1cs --wasm --sym -o build/

echo "[2/6] Computing the witness..."
node build/${CIRCUIT}_js/generate_witness.js \
    build/${CIRCUIT}_js/${CIRCUIT}.wasm \
    inputs/input.json \
    build/witness.wtns

echo "[3/6] Setup..."
snarkjs groth16 setup \
    build/${CIRCUIT}.r1cs \
    ${PTAU}.ptau \
    build/${CIRCUIT}_0000.zkey

echo "[4/6] Contribute to the ceremony..."
snarkjs zkey contribute \
    build/${CIRCUIT}_0000.zkey \
    build/${CIRCUIT}_0001.zkey \
    --name="1st Contributor Name" -v

echo "[5/6] Export the verification key"
snarkjs zkey export verificationkey \
    build/${CIRCUIT}_0001.zkey \
    build/verification_key.json

echo "[6/6] Generating proof..."
snarkjs groth16 prove \
  build/${CIRCUIT}_0001.zkey \
  build/witness.wtns \
  build/proof.json \
  build/public.json
