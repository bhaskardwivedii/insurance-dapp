// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Insurance {

    struct Policy {
        uint id;
        address policyHolder;
        uint premium;
        uint coverageAmount;
        bool isActive;
    }

    struct Claim {
        uint id;
        address policyHolder;
        uint policyId;
        uint claimAmount;
        bool approved;
        bool paid;
    }

    address public admin;
    uint public policyCount;
    uint public claimCount;

    mapping(uint => Policy) public policies;
    mapping(uint => Claim) public claims;

    event PolicyCreated(uint policyId, address policyHolder);
    event ClaimSubmitted(uint claimId, uint policyId, address policyHolder);
    event ClaimApproved(uint claimId);
    event PayoutProcessed(uint claimId, address policyHolder);

    constructor() {
        admin = msg.sender; // Set the deployer as the admin
    }

    // Allow the contract to receive Ether
    receive() external payable {}

    function createPolicy(uint premium, uint coverageAmount) public payable {
        require(msg.value == premium, "Premium must be paid in Ether");

        policyCount++;
        policies[policyCount] = Policy(policyCount, msg.sender, premium, coverageAmount, true);
        emit PolicyCreated(policyCount, msg.sender);
    }

    function submitClaim(uint policyId, uint claimAmount) public {
        require(policies[policyId].isActive, "Policy must be active");
        require(policies[policyId].policyHolder == msg.sender, "Only policyholder can submit claims");

        claimCount++;
        claims[claimCount] = Claim(claimCount, msg.sender, policyId, claimAmount, false, false);
        emit ClaimSubmitted(claimCount, policyId, msg.sender);
    }

    function approveClaim(uint claimId) public {
        require(msg.sender == admin, "Only admin can approve claims");
        Claim storage claim = claims[claimId];
        require(!claim.approved, "Claim already approved");

        claim.approved = true;
        emit ClaimApproved(claimId);
    }

    function processPayout(uint claimId) public {
        Claim storage claim = claims[claimId];
        require(claim.approved, "Claim is not approved");
        require(!claim.paid, "Payout already processed");
        require(address(this).balance >= claim.claimAmount, "Insufficient contract balance for payout");

        claim.paid = true;
        payable(claim.policyHolder).transfer(claim.claimAmount);
        emit PayoutProcessed(claimId, claim.policyHolder);
    }
}
