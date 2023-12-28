// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";

contract StrategyFactory {
    event StrategyCloned(address indexed newStrategy);

    function createStrategy(address _template) public returns (address) {
        address clone = Clones.clone(_template);
        emit StrategyCloned(clone);
        return clone;
    }
}