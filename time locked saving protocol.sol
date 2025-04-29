// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TimeLockedSavings
 * @dev A simple time-locked savings protocol for CoreDAO
 */
contract TimeLockedSavings {
    // Structure to store deposit information
    struct Deposit {
        uint256 amount;      // Amount deposited
        uint256 unlockTime;  // Timestamp when the deposit becomes available
        bool withdrawn;      // Whether the deposit has been withdrawn
    }
     
    // Early withdrawal fee percentage (10%)
    uint256 public constant EARLY_WITHDRAWAL_FEE = 10;
    
    // Mapping of user addresses to their deposits
    mapping(address => Deposit[]) public deposits;
    
    // Events
    event Deposited(address indexed user, uint256 amount, uint256 unlockTime);
    event Withdrawn(address indexed user, uint256 amount, bool penaltyApplied);
    
    /**
     * @dev Creates a new time-locked deposit
     * @param _lockDuration The duration (in seconds) for which the funds will be locked
     */
    function deposit(uint256 _lockDuration) external payable {
        require(msg.value > 0, "Amount must be greater than 0");
        require(_lockDuration > 0, "Lock duration must be greater than 0");
        
        // Calculate the unlock timestamp
        uint256 unlockTime = block.timestamp + _lockDuration;
        
        // Store the deposit details
        deposits[msg.sender].push(Deposit({
            amount: msg.value,
            unlockTime: unlockTime,
            withdrawn: false
        }));
        
        emit Deposited(msg.sender, msg.value, unlockTime);
    }
    
    /**
     * @dev Withdraws funds from a deposit
     * @param _depositIndex The index of the deposit in the user's deposit array
     */
    function withdraw(uint256 _depositIndex) external {
        require(_depositIndex < deposits[msg.sender].length, "Invalid deposit index");
        
        Deposit storage userDeposit = deposits[msg.sender][_depositIndex];
        require(!userDeposit.withdrawn, "Deposit already withdrawn");
        
        uint256 amount = userDeposit.amount;
        bool earlyWithdrawal = block.timestamp < userDeposit.unlockTime;
        
        // Mark deposit as withdrawn
        userDeposit.withdrawn = true;
        
        // Apply early withdrawal fee if applicable
        if (earlyWithdrawal) {
            uint256 fee = (amount * EARLY_WITHDRAWAL_FEE) / 100;
            amount -= fee;
        }
        
        // Transfer funds to the user
        payable(msg.sender).transfer(amount);
        
        emit Withdrawn(msg.sender, amount, earlyWithdrawal);
    }
    
    /**
     * @dev Gets all deposits for the caller
     * @return An array of all deposits made by the caller
     */
    function getMyDeposits() external view returns (Deposit[] memory) {
        return deposits[msg.sender];
    }
}
