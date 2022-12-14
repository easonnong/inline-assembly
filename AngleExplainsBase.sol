// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract AngleExplainsBase {
    uint private secretNumber;
    mapping(address => uint) public guesses;
    bytes32 public secretWord;

    // 23523 gas when called by a contract
    function getSecretNumber() external view returns (uint) {
        return secretNumber;
    }

    // 23869 gas
    function setSecretNumber(uint number) external {
        secretNumber = number;
    }

    // 43814 fist time -> and then 23914 gas
    function addGuess(uint _guess) external {
        guesses[msg.sender] = _guess;
    }

    // 70217 gas fist time -> and then 30417 gas
    function addMultipleGuesses(address[] memory _users, uint[] memory _guesses)
        external
    {
        for (uint i = 0; i < _users.length; i++) {
            guesses[_users[i]] = _guesses[i];
        }
    }

    // "hello" 25252 gas
    function hashSecretWord(string memory _str) external {
        secretWord = keccak256(abi.encodePacked(_str));
    }
}

contract AngleExplainsBaseAssembly {
    uint private secretNumber;
    mapping(address => uint) public guesses;
    bytes32 public secretWord;

    function getSecretNumber() external view returns (uint) {
        /*assembly{
            // 23354 gas when called by a contract
            let _secretNumber := sload(0)
            let ptr := mload(0x40)
            mstore(ptr, _secretNumber)
            return(ptr,0x20)
        }*/
        assembly {
            // 23342 when called by a contract
            let _secretNumber := sload(0)
            mstore(0, _secretNumber)
            return(0, 0x20)
        }
    }

    // 23866 gas
    function setSecretNumber(uint _number) external {
        assembly {
            let slot := secretNumber.slot
            sstore(slot, _number)
        }
    }

    // 43807 fist time -> and then 23907 gas
    function addGuess(uint _guess) external {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, caller())
            mstore(add(ptr, 0x20), guesses.slot)
            let slot := keccak256(ptr, 0x40)
            sstore(slot, _guess)
        }
    }

    // 69891 gas fist time -> and then 30091 gas
    function addMultipleGuesses(address[] memory _users, uint[] memory _guesses)
        external
    {
        assembly {
            let usersSize := mload(_users)
            let guessesSize := mload(_guesses)
            for {
                let i := 0
            } lt(i, usersSize) {
                i := add(i, 1)
            } {
                let userAddr := mload(add(_users, mul(0x20, add(i, 1))))
                let userBalance := mload(add(_guesses, mul(0x20, add(i, 1))))
                mstore(0, userAddr)
                mstore(0x20, guesses.slot)
                let slot := keccak256(0, 0x40)
                sstore(slot, userBalance)
            }
        }
    }

    // "hello" 24789 gas
    function hashSecretWord(string memory _str) external {
        assembly {
            let strSize := mload(_str)
            let hash := keccak256(add(0x80, 0x20), strSize)
            let slot := secretWord.slot
            sstore(slot, hash)
        }
    }

    // "hello" 24335 gas
    function hashSecretWord2(string calldata) external {
        assembly {
            let strOffset := add(4, calldataload(4))
            let strSize := calldataload(strOffset)
            let ptr := mload(0x40)
            calldatacopy(ptr, add(strOffset, 0x20), strSize)
            let hash := keccak256(ptr, strSize)
            sstore(secretWord.slot, hash)
        }
    }
}
