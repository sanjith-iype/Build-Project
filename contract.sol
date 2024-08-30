// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    struct Milestone {
        uint256 amount;
        string description;
        bool approved;
        uint256 voteCount;
        mapping(address => bool) voters;
    }

    struct Campaign {
        uint256 id;
        string name;
        string description;
        uint256 targetAmount;
        uint256 deadline;
        address payable creator;
        uint256 totalContributions;
        bool finalized;
        mapping(uint256 => Milestone) milestones;
        uint256 milestoneCount;
        mapping(address => uint256) contributions;
        address[] contributors;
        mapping(address => bool) refundClaimed;
    }

    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;

    event CampaignCreated(uint256 indexed campaignId, address indexed creator, string name, uint256 targetAmount, uint256 deadline);
    event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event MilestoneApproved(uint256 indexed campaignId, uint256 indexed milestoneIndex);
    event FundsReleased(uint256 indexed campaignId, uint256 indexed milestoneIndex, uint256 amount);
    event RefundClaimed(uint256 indexed campaignId, address indexed contributor);
    event CampaignFinalized(uint256 indexed campaignId, bool successful);

    // Function to create a new campaign with all the necessary parameters
    function createCampaign(
        string memory name,
        string memory description,
        uint256 targetAmount,
        uint256 deadline,
        uint256[] memory milestoneAmounts,
        string[] memory milestoneDescriptions
    ) public {
        require(deadline > block.timestamp, "Deadline must be in the future"); // keeps the requirements necessary
        require(milestoneAmounts.length == milestoneDescriptions.length, "Milestones data mismatch");

        campaignCount++;  // Increment campaignCount to get a new unique campaign ID
        Campaign storage newCampaign = campaigns[campaignCount];  // Use campaignCount as the new campaign ID
        newCampaign.id = campaignCount;  // Assign the campaign ID
        newCampaign.name = name;
        newCampaign.description = description;
        newCampaign.targetAmount = targetAmount;
        newCampaign.deadline = deadline;
        newCampaign.creator = payable(msg.sender);
        newCampaign.finalized = false;

        for (uint256 i = 0; i < milestoneAmounts.length; i++) {
            newCampaign.milestones[i].amount = milestoneAmounts[i];
            newCampaign.milestones[i].description = milestoneDescriptions[i];
            newCampaign.milestones[i].approved = false;
            newCampaign.milestones[i].voteCount = 0;
        }

        newCampaign.milestoneCount = milestoneAmounts.length;

        // Emit the CampaignCreated event with the campaign ID
        emit CampaignCreated(campaignCount, msg.sender, name, targetAmount, deadline);
    }

    function contribute(uint256 campaignId) public payable { //function to contribute ethereum to campaign of choice
        Campaign storage campaign = campaigns[campaignId];
        require(block.timestamp < campaign.deadline, "Campaign has ended"); //all the requirements needed to contribute
        require(campaign.totalContributions < campaign.targetAmount, "Target already reached");
        require(!campaign.finalized, "Campaign is finalized");

        // Ensure that the sent value is greater than zero
        require(msg.value > 0, "Contribution must be greater than zero");

        // Check if the sender has contributed before
        if (campaign.contributions[msg.sender] == 0) {
            campaign.contributors.push(msg.sender);
        }

        // Update contribution and total contributions
        campaign.contributions[msg.sender] += msg.value;
        campaign.totalContributions += msg.value;

        // Emit an event to log the contribution
        emit ContributionMade(campaignId, msg.sender, msg.value);
    }
    //gets the timestamp so that you can put the deadline time based on the timestamp
    function getCurrentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    // function that approves Milestones
    function approveMilestone(uint256 campaignId, uint256 milestoneIndex) public {
        Campaign storage campaign = campaigns[campaignId];
        Milestone storage milestone = campaign.milestones[milestoneIndex];
        require(block.timestamp < campaign.deadline, "Campaign has ended"); //all requirements needed to approve milestones
        require(campaign.contributions[msg.sender] > 0, "Only contributors can vote");
        require(!milestone.voters[msg.sender], "Already voted for this milestone");

        milestone.voters[msg.sender] = true;
        milestone.voteCount++;
        // checks if the vote should be approved
        if (milestone.voteCount > campaign.contributors.length / 2) {
            milestone.approved = true;
            campaign.creator.transfer(milestone.amount);

            emit MilestoneApproved(campaignId, milestoneIndex);
            emit FundsReleased(campaignId, milestoneIndex, milestone.amount);
        }
    }
    //function to claim a refund
    function claimRefund(uint256 campaignId) public {
        Campaign storage campaign = campaigns[campaignId];
        require(block.timestamp >= campaign.deadline, "Campaign is still active"); //all needed requirements
        require(campaign.totalContributions < campaign.targetAmount, "Campaign was successful");
        require(campaign.contributions[msg.sender] > 0, "No contribution found");
        require(!campaign.refundClaimed[msg.sender], "Refund already claimed");

        uint256 refundAmount = campaign.contributions[msg.sender];
        campaign.refundClaimed[msg.sender] = true;
        payable(msg.sender).transfer(refundAmount);

        emit RefundClaimed(campaignId, msg.sender);
    }
    //function to end the campaigns based on certain parameters
    function finalizeCampaign(uint256 campaignId) public {
        Campaign storage campaign = campaigns[campaignId];
        require(block.timestamp >= campaign.deadline, "Campaign is still active");
        require(!campaign.finalized, "Campaign is already finalized");

        if (campaign.totalContributions >= campaign.targetAmount) {
            emit CampaignFinalized(campaignId, true);
        } else {
            emit CampaignFinalized(campaignId, false);
        }

        campaign.finalized = true;
    }

    // View functions
    function getCampaignDetails(uint256 campaignId) public view returns (
        uint256 id,
        string memory name,
        string memory description,
        uint256 targetAmount,
        uint256 deadline,
        address creator,
        uint256 totalContributions,
        bool finalized
    ) {
        Campaign storage campaign = campaigns[campaignId];
        return (
            campaign.id,
            campaign.name,
            campaign.description,
            campaign.targetAmount,
            campaign.deadline,
            campaign.creator,
            campaign.totalContributions,
            campaign.finalized
        );
    }
    //gets the information on the contributor
    function getContributorInfo(uint256 campaignId, address contributor) public view returns (
        uint256 contribution,
        bool refundClaimed
    ) {
        Campaign storage campaign = campaigns[campaignId];
        return (
            campaign.contributions[contributor],
            campaign.refundClaimed[contributor]
        );
    }

    function getMilestoneStatus(uint256 campaignId, uint256 milestoneIndex) public view returns (
        uint256 amount,
        string memory description,
        bool approved,
        uint256 voteCount
    ) {
        Campaign storage campaign = campaigns[campaignId];
        Milestone storage milestone = campaign.milestones[milestoneIndex];
        return (
            milestone.amount,
            milestone.description,
            milestone.approved,
            milestone.voteCount
        );
    }
    //pulls out all campaigns
    function getAllCampaigns() public view returns (uint256[] memory) {
        uint256[] memory campaignIds = new uint256[](campaignCount);
        for (uint256 i = 1; i <= campaignCount; i++) {
            campaignIds[i - 1] = campaigns[i].id;
        }
        return campaignIds;
    }

    function getCampaignContributors(uint256 campaignId) public view returns (address[] memory) {
        Campaign storage campaign = campaigns[campaignId];
        return campaign.contributors;
    }

    function getTotalContributions(uint256 campaignId) public view returns (uint256) {
        Campaign storage campaign = campaigns[campaignId];
        return campaign.totalContributions;
    }
}
