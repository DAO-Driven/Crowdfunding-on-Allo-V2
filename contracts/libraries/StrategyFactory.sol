// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title StrategyFactory
 * @dev This contract is used for creating clones of a strategy template.
 *      It leverages OpenZeppelin's Clones library for minimal proxy deployment.
 */
contract StrategyFactory {
    /// @notice Emitted when a new strategy clone is created.
    /// @param newStrategy The address of the newly cloned strategy.
    event StrategyCloned(address indexed newStrategy);

    /**
     * @notice Creates a clone of the strategy template.
     * @dev Uses the OpenZeppelin Clones library to create a minimal proxy clone of the strategy template.
     * @param _template The address of the strategy template to clone.
     * @return The address of the newly created strategy clone.
     */
    function createStrategy(address _template) public returns (address) {
        address clone = Clones.clone(_template);
        emit StrategyCloned(clone);
        return clone;
    }
}
