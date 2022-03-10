# Emergent Reputation System

## New Prespective
1. Get rid of signature lists for out-signatures
2. Get rid of all signatures at the CID payload layer.
3. ZK transfer of repuation to other identites through signing.
4. Cut edges on graph can also represent reputation.

- both of these we keep a list of the verfication keys (public account numbers) of individuals onchiani
- by signing the tx of keeping this list associated with the user account-number, we reduce the complexity of web of trust
    - by leveraging the offering of the underlying chain.


Trade off between 1 & 2 is graph traversal speed for shortest path.

## Problem Statement
The lack of reputation clearly associated with entities creating content on social media platforms like Twitter
creates an experience for users that requires them to excercise judgement to decide if an interaction is pure or malicious. Add to that foreign interference through coordinated efforts to produce
propoganda as described 
[here](https://symantec-enterprise-blogs.security.com/blogs/threat-intelligence/twitterbots-propaganda-disinformation),
and it clearly makes for an unusable experience for social communication and coordination. All of these problems result from a lack of a reliable reputation system.

## Solution
The natural aspect of interactions between agents in the metaverse help to determine the reliability of individuals.
We leverage this charecteristic as a basis to build an emergent reputation system. This system is meant to emulate traditional
[key signing parties](https://en.wikipedia.org/wiki/Key_signing_party), in an automated and out-of-the-way fashion for lay users.

## Design Specification

### Identity payload
The input payload will consist of the verfication address associated with the User we will describe as _U<sub>orginal</sub>_.

After interacting with _U<sub>original</sub>_ , an arbtirary user _U<sub>adj</sub>_ can sign the 
verfication key of _U<sub>orginal</sub>_. This will produce a signature that  _U<sub>orginal</sub>_ can append to their 
signature list along with their associated public key/verfication key. To incentivise _U<sub>adj</sub>_ to conduct due dilligence, 
they signing will incurr a cost onto _U<sub>adj</sub>_ with a possibilty of accruing rewards for the action (TODO?).
![](/assets/diag1.jpg)

TODO(@ckartik): Keep both in-node and out-node per user signatures.

To make the resulting hash (CID) from the payload that contains the [web-of-trust](https://en.wikipedia.org/wiki/Web_of_trust) associated with the identity, easily accesible, we pin it to the smart-contract that will underpin this trust system.
### On Chain Pinning of Data
```solidity

contract Repuation {
    mapping (address=>string) Trusted;

    function update_trust_relations(string memory CID) public {
        Trusted[msg.sender] = CID;
    }
}
```
### Reputation Metrics
The reputation of an actor in this space is relational to others interacting with the actor.
Therefore the reputation-function will take two paramters, the requesting account number _U<sub>req</sub>_ and the
account number for which the reputation is being queried for _U<sub>query</sub>_. The result of this query will be the 
length of the shortest path between  _U<sub>req</sub>_ and _U<sub>query</sub>_ in the graph created via the signatures.

There is a third (implicitly defaulted) paramter assocaited with a terminal max-length, much like chain length in PKI.


### Questions
1. How do we prevent the contract from being ddosed or sybil attacked?
2. Privacy: How, if even possible, do we want to esnure the web-of-trust will remain private? This seems impossible but need to look into ZK Proofs.
3. Is a contract the best place to pin the CIDs?
4. Who would append signatures to the chain associated with an identity?
    - This would impact ability for signers to revoke the signatures.

## Possible things that can be built
1. Web3 Twitter
2. Web3 Facebook
3. Web3 Dating App

### Cryptonomics
- People can build their trust lists.
- Exposing to others can compensate them? In some form of staking - however, their stake can be lost.
- Drive monetary incentives to build a valuable web-of-trust.
- That turst infomration has inherent worth.