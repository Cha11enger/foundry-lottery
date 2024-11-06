// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function CreateSubscriptionUsingConfig() public returns (uint256, address) {
        // Create a subscription
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        (uint256 subId, ) = createSubscription(vrfCoordinator, account);
        return (subId, vrfCoordinator);

    }

    function createSubscription(address vrfCoordinator, address account) public returns (uint256, address) {
        console.log("Creating a subscription on chain id ", block.chainid);
        vm.startBroadcast(account);

        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();

        vm.stopBroadcast();

        console.log("Subscription created with id ", subId);
        return(subId, vrfCoordinator);
    }

    function run() public {
        CreateSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function FundSubscriptionUsingConfig() public {
        // Fund the subscription
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address link = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;
        fundSubscription(vrfCoordinator, subId, link, account);

      
    }

    function fundSubscription(address vrfCoordinator, uint256 subId, address link, address account) public {
        console.log("Funding subscription", subId);
        console.log("Using vrf coordinator", vrfCoordinator);
        console.log("on ChainId", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID){
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    
    }

    function run() public {
        FundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeplyed) public {
        // Add a consumer
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address account = helperConfig.getConfig().account;
        addConsumer(mostRecentlyDeplyed, vrfCoordinator, subId, account);
    }

    function addConsumer(address contractToAddTOVrf, address vrfCoordinator, uint256 subId, address account) public {
        console.log("Adding consumer to VRF Coordinator", vrfCoordinator);
        console.log("Consumer contract", contractToAddTOVrf);
        console.log("Subscription ID", subId);
        console.log("On ChainId", block.chainid);

        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddTOVrf);
        vm.stopBroadcast();
    }


    function run() external {
        // Add a consumer
        address mostRecentlyDeplyed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeplyed);
      
    }
}