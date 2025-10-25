import fs from "fs";
import { buildPoseidon } from "circomlibjs";

const toHex32 = x => "0x" + BigInt(x).toString(16).padStart(64, "0");
const nextPowerOf2 = n => 2 ** Math.ceil(Math.log2(Math.max(1, n)));

async function buildMerkleRootFirst(path) {
    const poseidon = await buildPoseidon();
    const F = poseidon.F;

    // wejście
    let leaves = fs.readFileSync(path, "utf8")
        .split("\n")
        .map(line => line.trim())
        .filter(line => line.length > 0)
        .map(s => BigInt(s));
    
    const leavesCount = nextPowerOf2(leaves.length);
    
    while (leaves.length < leavesCount) leaves.push(0n);

    const totalNodes = leavesCount * 2 - 1;
    const tree = new Array(totalNodes);

    const firstLeafIndex = Math.floor(totalNodes / 2);

    for (let i = 0; i < leavesCount; i++) {
        tree[firstLeafIndex + i] = leaves[i];
    }

    for (let i = firstLeafIndex - 1; i >= 0; i--) {
        const left = tree[2 * i + 1];
        const right = tree[2 * i + 2];
        tree[i] = F.toObject(poseidon([left, right]));
    }

    const lines = tree.map(toHex32);
    fs.writeFileSync("merkle_tree.txt", lines.join("\n") + "\n", "utf8");

    console.log("Root =", toHex32(tree[0]));
}

buildMerkleRootFirst("leafs.txt");
