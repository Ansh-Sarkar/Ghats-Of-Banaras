pragma solidity >=0.6.0 <0.9.0;

contract GOBDAOContract {
    // using SafeMath to avoid over or under flows in uint256
    using SafeMath for uint256;

    // The person who deploys the Vault is publicly visible as the
    // founder of the Vault
    address public founder;
    uint256 public minimumDeposit;
    uint256 public minimumWithdrawableAmount;
    uint256 public timeOut;
    uint256 public minimumBalanceToVote;
    uint256 public establishmentDate;
    uint256 public permissibleRatio;

    // Counters Section
    uint256 public totalProposals;
    uint256 public totalUsers;
    uint256 public DAOBalance;

    // UserData structure can be modified depending on how much
    // and what type of information we aim to store
    struct UserData {
        string name;
        uint256 balance;
    }
    // The Vault is made up of all its members and their data.
    // The address of the members are mapped to their details.
    // Note : The Vault is kept private.
    mapping(address=>UserData) private Vault;
    mapping(address=>uint256[]) private UserProposals;

    // Proposals are stored as (inside VaultProposals):
    // User {
    //     proposal_id ( = block.timestamp) {
    //          Proposal Data
    //     }
    // }
    struct Proposal {
        address owner;
        string ipfsLink;
        uint256 amount;
        mapping(address=>bool) votes;
        uint256 numberOfVotes;
        uint256 expiryDate;
        uint256 status;
    }
    // Allowed Statuses
    // 0 -> Success
    // 1 -> Expired
    // 2 -> Open
    mapping(address=>mapping(uint256=>Proposal)) private VaultProposals;

    modifier onlyMember {
        require(bytes(Vault[msg.sender].name).length > 0, "User not registered.");
        _;
    }

    // Person deploying the contract would become the Founder.
    // _name argument required for initializing founder as the
    // first registered user of the DAO
    constructor (
        string memory _name
    ) public {
        // Initialization Section
        founder = msg.sender;
        totalProposals = 0;
        totalUsers = 0;
        minimumDeposit = 0;
        minimumWithdrawableAmount = 0;
        timeOut = 600000;
        minimumBalanceToVote = 0;
        DAOBalance = 0;
        establishmentDate = now;
        permissibleRatio = 2;

        // Allocation and Creation Section
        UserData memory foundingUser = UserData({
            name : _name,
            balance : 0
        });
        // Adding the founder as our first registered user
        Vault[founder] = foundingUser;
        totalUsers.add(1);
    }

    // Registers a new user if not already present
    function registerNewMember(string memory _name) public returns(bool) {
        // If user already exists then reject request
        if(bytes(Vault[msg.sender].name).length > 0) return false;
        else {
            // Else create the user and initialize balance to 0
            UserData memory newUser = UserData({
                name : _name,
                balance : 0
            });
            Vault[msg.sender] = newUser;
            totalUsers.add(1);
            return true;
        }
    }

    // uint256 id;
    // string ipfsLink;
    // mapping(address=>bool) votes;
    // uint256 numberOfVotes;
    // uint256 expiryDate;
    // string status;
    function memberProposal(string memory _ipfsLink, uint256 _amount) public onlyMember returns(uint256) {
        // require(bytes(Vault[msg.sender].name).length > 0, "User not registered");
        require(_amount <= DAOBalance, "Amount to be withdrawn, exceeds limits.");
        require(_amount >= minimumWithdrawableAmount, "Amount to be withdrawn is too less");
        // mapping(address=>bool) votePool;
        uint256 frozenTime = now;
        Proposal memory newProposal = Proposal({
            owner : msg.sender,
            ipfsLink : _ipfsLink,
            amount : _amount,
            numberOfVotes : 0,
            expiryDate : frozenTime + timeOut,
            status : 2
        });
        VaultProposals[msg.sender][frozenTime] = newProposal;
        UserProposals[msg.sender].push(frozenTime);
        totalProposals.add(1);
        return frozenTime;
    }

    // Deposit to account
    function memberDeposit() external payable onlyMember returns(uint256) {
        require(msg.value >= minimumDeposit, "The amount is less than the minimum permissible deposit.");
        // require(bytes(Vault[msg.sender].name).length > 0, "User not registered");
        Vault[msg.sender].balance.add(msg.value);
        DAOBalance.add(msg.value);
        return Vault[msg.sender].balance;
    }

    // this transaction can be called only from inside the contract (programatically)
    function internallyInititatedWithdrawal(address _owner, uint256 _amount) internal returns(bool) {
        if(bytes(Vault[_owner].name).length <= 0) return false;
        if(_amount > Vault[_owner].balance || _amount < minimumWithdrawableAmount) return false;
        payable(_owner).transfer(_amount);
        DAOBalance.sub(_amount);
        return true;
    }

    // function to check and set the status of the proposal
    function checkStatus(uint256 _id, address _member) internal returns(uint256) {
        require(bytes(Vault[_member].name).length > 0, "User not found");
        require(bytes(VaultProposals[_member][_id].ipfsLink).length > 0, "Proposal not found");
        if(VaultProposals[_member][_id].status != 2) return VaultProposals[_member][_id].status;
        if(now > VaultProposals[_member][_id].expiryDate) {
            VaultProposals[_member][_id].status = 1;
            return 1;
        }
        if(totalUsers < 2 * VaultProposals[_member][_id].numberOfVotes) {
            VaultProposals[_member][_id].status = 0;
            bool status = internallyInititatedWithdrawal(_member, VaultProposals[_member][_id].amount);
            require(status, "Internally Initiated Withdrawal Failed");
            return 0;
        }
        return 3;
    }

    // function called by member to cast vote
    function memberVote(uint256 _id, address _member, uint256 vote) external onlyMember returns(bool) {
        // require(bytes(Vault[msg.sender].name).length > 0, "User not registered");
        require(Vault[msg.sender].balance >= minimumBalanceToVote, "You are not a large enough stakeholder");
        require(bytes(Vault[_member].name).length > 0, "User not found");
        require(bytes(VaultProposals[_member][_id].ipfsLink).length > 0, "Proposal not found");
        require(!VaultProposals[_member][_id].votes[msg.sender], "User has already casted Vote");

        uint256 status = checkStatus(_id, _member);
        if(status == 0 || status == 1 || status == 3) return false;
        else {
            VaultProposals[_member][_id].votes[msg.sender] = true;
            VaultProposals[_member][_id].numberOfVotes.add(1);
            return true;
        }
    }

    // Withdraw from account
    // function memberWithdraw(uint256 _amount) external onlyMember returns(uint256) {
    //     require(bytes(Vault[msg.sender].name).length > 0, "User not registered");
    //     require(_amount <= Vault[msg.sender].balance && _amount >= minimumWithdrawableAmount, "You do not have enough balance to withdraw or the requested amount is too less");
    //     payable(msg.sender).transfer(_amount);
    //     Vault[msg.sender].balance.sub(_amount);
    //     DAOBalance.sub(_amount);
    //     return Vault[msg.sender].balance;
    // }

    // Setter functions
    function setName(string memory _name) public onlyMember returns(string memory) {
        Vault[msg.sender].name = _name;
        return Vault[msg.sender].name;
    }

    // Getter functions
    function getProposal(uint256 _id) public view returns(string memory, uint256, uint256, uint256) {
        Proposal memory proposal = VaultProposals[msg.sender][_id];
        require(bytes(proposal.ipfsLink).length > 0, "Proposal Does Not Exist");
        return (proposal.ipfsLink, proposal.numberOfVotes, proposal.expiryDate, proposal.status);
    }
    function getName() public onlyMember returns(string memory) { return Vault[msg.sender].name; }
    function getMemberBalance() public onlyMember returns(uint256) { return Vault[msg.sender].balance; }
    function getFounder () public view returns(address) { return founder; }
    function getMinimumDeposit () public view returns(uint256) { return minimumDeposit; }
    function getMinimumWithdrawableAmount () public view returns(uint256) { return minimumWithdrawableAmount; }
    function getTimeOut () public view returns(uint256) { return timeOut; }
    function getBlockHeight () public view returns(uint256) { return now; }
    function getMinimumBalanceToVote () public view returns(uint256) { return minimumBalanceToVote; }
    function getEstablishmentDate () public view returns(uint256) { return establishmentDate; }
    function getTotalProposals () public view returns(uint256) { return totalProposals; }
    function getTotalUsers () public view returns(uint256) { return totalUsers; }
    function getDAOBalance () public view returns(uint256) { return DAOBalance; }
    function getPermissibleRatio () public view returns(uint256) { return permissibleRatio; }
}

// library to make sure that we dont overflow our integers under any circumstance . 256 bits => 32 bytes
library SafeMath {
    // check for integer overflows during addition
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        // if c < a => integer has wrapped around itself . Hence , overflow .
        require(c >= a, "SafeMath : addition overflow");
        return c;
    }
    // check for negative balances during subtraction
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b<=a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
}