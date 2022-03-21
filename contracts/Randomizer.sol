// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

contract Randomizer {
    uint256[256] private seeds;
    bytes public saltSeed;

    string public constant name = "BAM Randomizer";
    string public constant symbol = "Randomizer";

    constructor() {
        generateSeeds();
        generateSalt(name);
    }

    function generateSalt(string memory _salt) internal {
        saltSeed = bytes(_salt);
    }

    function getRandom(uint256 _any, uint256 _length)
        public
        view
        returns (uint256)
    {
        uint8 index = uint8(_random(keccak256(abi.encode(_any)), 10));
        return _random(keccak256(abi.encode(seeds[index], saltSeed)), _length);
    }

    function generateSeeds() public {
        for (uint256 index = 0; index < 256; index++) {
            bytes32 _bytes32 = keccak256(
                abi.encodePacked(block.number, block.timestamp, index)
            );
            seeds[index] = _random(_bytes32, 3);
        }
    }

    function _random(bytes32 _seed, uint256 _length)
        private
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        _seed,
                        _length,
                        keccak256(abi.encodePacked(block.coinbase)),
                        keccak256(abi.encodePacked(msg.sender))
                    )
                )
            ) % (10**_length);
    }
}
