pragma solidity >=0.6.0 <0.9.0;

contract TestContract {
    string private name;
    constructor(string memory _name) public {
        name = _name;
    }
    function getName() public view returns(string memory) {
        return string(name);
    }
}