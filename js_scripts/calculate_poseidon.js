import { buildPoseidon } from "circomlibjs";

async function main() {
    const poseidon = await buildPoseidon();
    const secret = BigInt("A".charCodeAt(0));
    const hash = poseidon.F.toObject(poseidon([secret]));
    console.log("Poseidon(secret) =", "0x"+hash.toString(16).padStart(64, "0"));
}

main();
