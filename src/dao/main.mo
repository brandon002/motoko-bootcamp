import Result "mo:base/Result";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Debug "mo:base/Debug";
import Time "mo:base/Time";
import Nat64 "mo:base/Nat64";
import Map "mo:map/Map";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Types "types";
actor DAO {

    type Result<A, B> = Result.Result<A, B>;
    type Member = Types.Member;
    type ProposalContent = Types.ProposalContent;
    type ProposalId = Types.ProposalId;
    type Proposal = Types.Proposal;
    type Vote = Types.Vote;
    type HttpRequest = Types.HttpRequest;
    type HttpResponse = Types.HttpResponse;
    type Stats = Types.Stats;
    stable let canisterIdWebpage : Principal = Principal.fromText("2iql3-oiaaa-aaaab-qacja-cai"); // TODO: Change this to the ID of your webpage canister
    stable var manifesto = "Empower the next generation of builders and make the DAO-revolution a reality";
    stable let name = "bnx";
    let eq: (Nat,Nat) ->Bool = func(x, y) { x == y };
    let proposals = HashMap.HashMap<ProposalId, Proposal>(0, eq, Hash.hash);
    stable var goals = ["Explore DAO and build Dapps with Motoko"];
    let members = HashMap.HashMap<Principal, Member>(0, Principal.equal, Principal.hash);

    func _initialMember(p : Principal) : () {
        members.put(
            Principal.fromText("gth2f-eyaaa-aaaaj-qa2pq-cai"),
            {
                name = "motoko_bootcamp";
                role = #Mentor;
            },
        );
    };
    // func _initialMint (p: Principal, amount: Nat) : async Result<(), Text>{
    //     await canisterToken.mint(Principal.fromText("gth2f-eyaaa-aaaaj-qa2pq-cai"), 10);
    // };

    _initialMember(Principal.fromText("gth2f-eyaaa-aaaaj-qa2pq-cai"));
    // (async func(){
    //     await _initialMint(Principal.fromText("gth2f-eyaaa-aaaaj-qa2pq-cai"));
    // })();

    let canisterToken = actor ("jaamb-mqaaa-aaaaj-qa3ka-cai") : actor {
        mint : shared (memberP : Principal, amount : Nat) -> async Result<(), Text>;
        balanceOf : shared query(memberP : Principal) -> async Nat;
        burn : shared (memperP : Principal, amount : Nat) -> async Result<(), Text>;
        totalSupply : shared query() -> async Nat;
    };
    // public shared func tesmint(): () {
    //     ignore await canisterToken.mint(Principal.fromText("gth2f-eyaaa-aaaaj-qa2pq-cai"), 10);
    // };
    // tesmint();
    // func (): async (){await _tesmint()};
    public func balanceGet(p : Principal) : async Nat {
        return await canisterToken.balanceOf(p);
    };
    // Returns the name of the DAO
    public query func getName() : async Text {
        return name;
    };

    // Returns the manifesto of the DAO
    public shared query func getManifesto() : async Text {
        return manifesto;
    };
    public func setManifesto(newManifesto : Text) : () {
        manifesto := newManifesto;
    };
    // Returns the goals of the DAO
    public query func getGoals() : async [Text] {
        return goals;
    };

    // Register a new member in the DAO with the given name and principal of the caller
    // Airdrop 10 MBC tokens to the new member
    // New members are always Student
    // Returns an error if the member already exists
    public shared ({ caller }) func registerMember(name : Text) : async Result<(), Text> {
        switch (members.get(caller)) {
            case (null) {
                members.put(
                    caller,
                    {
                        name = name;
                        role = #Student;
                    },
                );
                await canisterToken.mint(caller, 10);
                // return #ok();
            };
            case (?member) {
                return #err("Already a Member!");
            };
        };
    };

    // Get the member with the given principal
    // Returns an error if the member does not exist
    public query func getMember(p : Principal) : async Result<Member, Text> {
        switch (members.get(p)) {
            case (null) {
                return #err("Member not found!");
            };
            case (?member) {
                return #ok(member);
            };
        };
    };
    // public func getBalance(p: Principal) : async (){
    //     Debug.print(debug_show (await canisterToken.balanceOf(p)));
    // };
    func _getMembers() : [Text] {
        let buffer = Buffer.Buffer<Text>(0);
        for (member in members.vals()) {
            buffer.add(member.name);
        };
        return Buffer.toArray(buffer);
    };
    public query func getStats() : async Stats {
        return ({
            name = name;
            manifesto = manifesto;
            goals = goals;
            members = _getMembers();
            // logo = logo;
            numberOfMembers = members.size();
        });
    };
    // Graduate the student with the given principal
    // Returns an error if the student does not exist or is not a student
    // Returns an error if the caller is not a mentor
    public shared ({ caller }) func graduate(student : Principal) : async Result<(), Text> {
        switch (members.get(caller)) {
            case (null) {
                return #err("Caller not a member!");
            };
            case (?member) {
                switch (member.role) {
                    case (#Mentor) {
                        switch (members.get(student)) {
                            case (null) {
                                return #err("Student not found!");
                            };
                            case (?studentFound) {
                                switch (studentFound.role) {
                                    case (#Student) {
                                        members.put(
                                            student,
                                            {
                                                name = studentFound.name;
                                                role = #Graduate;
                                            },
                                        );
                                        return #ok();
                                    };
                                    case (_) {
                                        return #err("Member is not a student!");
                                    };
                                };
                            };
                        };
                    };
                    case (_) {
                        return #err("Only a Mentor can Graduate a Student!");
                    };
                };
            };
        };
    };

    // Create a new proposal and returns its id
    // Returns an error if the caller is not a mentor or doesn't own at least 1 MBC token
    var currentProposalId : ProposalId = 1;
    public shared ({ caller }) func createProposal(content : ProposalContent) : async Result<ProposalId, Text> {
        let p = Principal.fromText("gth2f-eyaaa-aaaaj-qa2pq-cai");
        switch (members.get(caller)) {
            case (null) {
                return #err("Member not found!");
            };
            case (?member) {
                switch (member.role) {
                    case (#Mentor) {
                        let balance = await canisterToken.balanceOf(caller);
                        let supp : Nat = await canisterToken.totalSupply();

                        if (balance < 1) {
                            if (supp == 0) {
                                if (Principal.equal(caller, p)) {
                                    var currentId = currentProposalId;
                                    let proposal : Proposal = {
                                        id = currentId;
                                        content = content;
                                        creator = caller;
                                        created = Time.now();
                                        executed = null;
                                        votes = [];
                                        voteScore = 0;
                                        status = #Open;
                                    };
                                    proposals.put(currentId, proposal);
                                    currentProposalId += 1;
                                    ignore await canisterToken.mint(Principal.fromText("gth2f-eyaaa-aaaaj-qa2pq-cai"), 9);
                                    return #ok(currentId);
                                } else{
                                    return #err("Member not have enough token!(Min.1)");
                                };
                            } else{
                                return #err("Member not have enough token!(Min.1)");
                            }
                        };
                        var currentId = currentProposalId;
                        let proposal : Proposal = {
                            id = currentId;
                            content = content;
                            creator = caller;
                            created = Time.now();
                            executed = null;
                            votes = [];
                            voteScore = 0;
                            status = #Open;
                        };
                        proposals.put(currentId, proposal);
                        currentProposalId += 1;

                        switch (await canisterToken.burn(caller, 1)) {
                            case (#ok) {
                                return #ok(currentId);
                            };
                            case (_) {
                                return #err("Burn Failed");
                            };
                        };
                    };
                    case (_) {
                        return #err("Only mentor can create proposal!");
                    };
                };
            };
        };
    };

    // Get the proposal with the given id
    // Returns an error if the proposal does not exist
    public query func getProposal(id : ProposalId) : async Result<Proposal, Text> {
        switch (proposals.get(id)) {
            case (null) {
                return #err("No proposal found!");
            };
            case (?proposal) {
                return #ok(proposal);
            };
        };
    };

    // Returns all the proposals
    public query func getAllProposal() : async [Proposal] {
        return Iter.toArray(proposals.vals());
    };

    // Vote for the given proposal
    // Returns an error if the proposal does not exist or the member is not allowed to vote
    func _hasVoted(proposal : Proposal, member : Principal) : Bool {
        return Array.find<Vote>(
            proposal.votes,
            func(vote : Vote) {
                return vote.member == member;
            },
        ) != null;
    };
    public func addGoal(newGoal : Text) : () {
        let goalsBuffer = Buffer.Buffer<Text>(0);
        for (goal in goals.vals()) {
            goalsBuffer.add(goal);
        };
        goalsBuffer.add(newGoal);
        goals := Buffer.toArray(goalsBuffer);
    };
    func _executeProposal(content : ProposalContent) : async () {
        switch (content) {
            case (#ChangeManifesto(newManifesto)) {
                manifesto := newManifesto;
            };
            case (#AddGoal(newGoal)) {
                addGoal(newGoal);
            };
            case (#AddMentor(newMentor)) {
                switch (await graduate(newMentor)) {
                    case (_) {
                        return;
                    };
                };
            };
        };
        return;
    };
    public shared ({ caller }) func voteProposal(proposalId : ProposalId, yesOrNo : Bool) : async Result<(), Text> {
        switch (members.get(caller)) {
            case (null) {
                #err("Member not found!");
            };
            case (?member) {
                if (member.role == #Student) {
                    return #err("Only graduate or mentor can vote!");
                };
                switch (proposals.get(proposalId)) {
                    case (null) {
                        #err("Proposal not found!");
                    };
                    case (?proposal) {
                        if (proposal.status != #Open) {
                            return #err("Proposal executed/inactive!");
                        };
                        if (_hasVoted(proposal, caller)) {
                            return #err("Member already voted this proposal!");
                        };
                        let balance = await canisterToken.balanceOf(caller);
                        var votingPower = 0;
                        if (member.role == #Mentor) {
                            votingPower := balance * 5;
                        } else {
                            votingPower := balance;
                        };
                        let multiplierVote = switch (yesOrNo) {
                            case (true) { 1 };
                            case (false) { -1 };
                        };
                        let currentVoteScore = proposal.voteScore + votingPower * multiplierVote;
                        var currentExecuted : ?Time.Time = null;
                        let newVotes = Buffer.fromArray<Vote>(proposal.votes);
                        let newStatus = if (currentVoteScore >= 100) {
                            #Accepted;
                        } else if (currentVoteScore <= -100) {
                            #Rejected;
                        } else {
                            #Open;
                        };
                        switch (newStatus) {
                            case (#Accepted) {
                                await _executeProposal(proposal.content);
                                currentExecuted := ?Time.now();
                            };
                            case (_) {};
                        };
                        let newProposal : Proposal = {
                            id = proposal.id;
                            content = proposal.content;
                            creator = proposal.creator;
                            created = proposal.created;
                            executed = currentExecuted;
                            votes = Buffer.toArray(newVotes);
                            voteScore = currentVoteScore;
                            status = newStatus;
                        };
                        proposals.put(proposal.id, newProposal);
                        return #ok();
                    };
                };
            };
        };
    };

    // Returns the Principal ID of the Webpage canister associated with this DAO
    public query func getIdWebpage() : async Principal {
        return canisterIdWebpage;
    };

};
