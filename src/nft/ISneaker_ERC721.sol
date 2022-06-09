// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISneaker_ERC721 {
    enum Class {
        Common,
        Uncommon,
        Rare,
        Epic,
        Legendary,
        Mythic
    }

    struct SneakerStats {
        uint32 class;
        uint32 generation;
        uint32 globalPoints;
        uint32 running;
        uint32 walking;
        uint32 biking;
        uint32 factoryUsed;
        uint32 energy;
    }
}