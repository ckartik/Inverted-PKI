// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "hardhat/console.sol";

contract Reputation {
    bytes REK;
    bytes tag;

    // Note: Reward/Payment recieved to Bob will be slightly less than what Alice pays due to network fees.
    uint paymentValue;

    constructor() {
        paymentValue = 10**15;
    }
    
    /*
        The payment lifecycle of a proposal flow steps through 3 (+1 implict) phases.

        - When an entity requests the trust graph of an individual it
          gets put into a REQUESTED state.

        - When this entity has been responded to by the owner of the trust graph
          with a re-encryption key, the phase steps to responded.

        - @(ckartik): TODO: Implement a proper validation step using ZK proofs of 
                      correct re-encryption key generation.
        The final step is closed, when the re-encryption key has been deemed valid.
        This can be done when an optimistic oracle has not disputed a correctness claim
        or if a certificate ZK Proof is provided.

        TODO(@ckartik): Need a way to reset this lifecycle back to intial state.
    */
    enum PaymentLifeCycle {UNSET_OR_CLEARED,REQUESTED,RESPONDED}
    enum DataPrivacyTier {T0, T1, T2, T3}

    // This event will be emited to notify that a transaction lifecycle has changed.
    event transactionLifeCycleChanged (
        PaymentLifeCycle newState,
        address indexed customer,
        address indexed locksmith
    );

    event tierRequested (
        DataPrivacyTier tier,
        address indexed customer,
        address indexed locksmith
    );

    // REKs are a set of Re-encryption keys posted to respond to a payment request for the users trust list.
    mapping (address=>mapping(address=>string)) REKs;

    function getAddress() public view returns (address) {
        return msg.sender;
    }

    // Pair of relevant values to move through queue.
    mapping(address=>address[]) requestQueue;
    mapping(address=>uint256) handled;

    // Owner of CID -> requesting adr ->
    mapping (address=>mapping(address=>DataPrivacyTier)) requestedTier;
    // Owner of CID => Requesting Address -> Stage
    mapping (address=>mapping(address=>PaymentLifeCycle)) requestForREKStage;
    // Owner of CID -> Requesting Address -> REK
    mapping (address=>mapping(address=>bytes)) rekPerUser;
    // Requesting Address -> Public Key
    mapping (address=>bytes) publicKeys;

    function getRequestedTier(address customer) public view returns (DataPrivacyTier) {
        return requestedTier[msg.sender][customer];
    }

    function getCurrentREKRequestState(address locksmith) public view returns (PaymentLifeCycle) {
        return requestForREKStage[locksmith][msg.sender];
    }

    function getPublicKey(address targetAddress) public view returns (bytes memory) {
        return publicKeys[targetAddress];
    }

    function getCustomerList() public view returns (address[] memory) {
        return requestQueue[msg.sender];
    }
    
    /* 
        TODO(@ckartik): Vunreability.
        Need to somehow block an attack where users overload the list with requests.
    */
    function makeRequestForTrustRelationsDecryption(address locksmith, bytes memory publicKey, DataPrivacyTier tier) payable public {
        // Require user at this stage to not be in requested/responded state.
        require(requestForREKStage[locksmith][msg.sender] == PaymentLifeCycle.UNSET_OR_CLEARED, "ALREADY_REQUESTED");
        // TODO(@ckartik): Keep thinking about it
        require(msg.value >= 10**11, "INSUFICENT_PAYMENT");
        requestQueue[locksmith].push(msg.sender);
        publicKeys[msg.sender] = publicKey;
        requestedTier[locksmith][msg.sender] = tier;

        // Note(@ckartik): Always change lifecycle state after all other state changes in function.
        requestForREKStage[locksmith][msg.sender] = PaymentLifeCycle.REQUESTED;

        emit transactionLifeCycleChanged(
            PaymentLifeCycle.REQUESTED,
            msg.sender,
            locksmith
        );
    }

    /* 
        Get the re-encryption key.
        Requires state transition to be at the point where a key exists in the smart-contract.
    */
    function getReKey(address locksmith) public view returns (bytes memory r1, bytes memory r2,bytes memory r3) {
        require(requestForREKStage[locksmith][msg.sender] == PaymentLifeCycle.RESPONDED, "INVALID_STATE_TRANSITION");

        (r1,r2,r3) = abi.decode(rekPerUser[locksmith][msg.sender], (bytes,bytes,bytes));
    }

    /*
        Function invoked by the owner to post a key - requires passed requesting address to have made payment and requested keys.
    */
    function postReKey(address customer, bytes memory r1, bytes memory r2, bytes memory r3) public {
        require(requestForREKStage[msg.sender][customer] == PaymentLifeCycle.REQUESTED, "INVALID_STATE_TRANSITION");
        
        rekPerUser[msg.sender][customer] = abi.encode(r1,r2,r3);

        requestForREKStage[msg.sender][customer] = PaymentLifeCycle.RESPONDED;
        emit transactionLifeCycleChanged(
            PaymentLifeCycle.RESPONDED,
            customer,
            msg.sender
        );
    }
   

    /* 
        This method will clear funds to Alice once the exchange has been completed.
    */
    function clearFunds(address customer) payable public {
        require(requestForREKStage[msg.sender][customer] == PaymentLifeCycle.RESPONDED, "INVALID_STATE_TRANSITION");

        payable(msg.sender).transfer(paymentValue);
        requestForREKStage[msg.sender][customer] = PaymentLifeCycle.UNSET_OR_CLEARED;
        emit transactionLifeCycleChanged(
            PaymentLifeCycle.UNSET_OR_CLEARED,
            customer,
            msg.sender
        );
    }
    
    /*
        Free Look up of CID info.
            - If un-encrypted, the data will be accessible without requirement of payment.
    */
     
    // Trusted presents a mapping between addresses and the CIDs holding a list of nodes 
    // that are part of it's edge set.
    mapping (address=>string) Trusted;

    // Overloaded for backward comptitatibilty
    function getCIDFor(address query) public view returns (string memory) {
        return Trusted[query];
    }

    function getCID() public view returns (string memory) {
        console.log("SMART CONTRACT: GETCID %s ", msg.sender);
        console.log("Stored CID is the following %s", Trusted[msg.sender]);
        return Trusted[msg.sender];
    }

    function updateTrustRelations(string memory CID) public {
        console.log("SMART CONTRACT: SENDER %s ", msg.sender);
        console.log("SMART CONTRACT: SENDER CID %s ", CID);
        Trusted[msg.sender] = CID;
    }

    function removeTrustRelations() public {
        if (bytes(Trusted[msg.sender]).length == 0) {
            console.log("Sender %s has no data stored in the system", msg.sender);
            return;
        }
        delete Trusted[msg.sender];
        console.log("Sender %s has been removed from the system", msg.sender);
    }
    
}
