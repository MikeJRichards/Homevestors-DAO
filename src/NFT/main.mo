import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Hash "mo:base/Hash";
import Nat64 "mo:base/Nat64";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";

actor SimpleNFTCollection {

    // Type Definitions
    public type TokenId = Nat;
    public type CollectionId = Nat;
    public type Attribute = { key: Text; value: Text };
    public type Hash = Hash.Hash;
    public type Result<A,B> = Result.Result<A,B>;

    public type Account = {
        owner: Principal;
        subaccount: ?Blob;
    };

    public type Metadata = {
        name: Text;
        description: Text;
        image: Text; // URL to the image
        creator: Principal;
        creationDate: Int;
        attributes: [Attribute];
        collectionId: CollectionId;
        fractionalOwnership: Nat;  // Represents 0.1% ownership
        spvDetails: Text; // SPV registration details or a link to the document
        financialTerms: Text; // Financial terms like dividend policies
    };

    public type Token = {
        id: TokenId;
        owner: Account;
        metadata: Metadata;
    };

    public type TransactionTypes = {
        #Mint;
        #Transfer;
    };

    public type Transaction = {
        id: Nat;
        action: TransactionTypes;
        tokenId: TokenId;
        from: ?Account;
        to: ?Account;
        timestamp: Int;
    };

    

    public type Proposal = {
        id: Nat;
        description: Text;
        yesVotes: Nat;
        noVotes: Nat;
        endTime: Nat64;
        executed: Bool;
    };

    public type Collection = {
        name: Text;
        description: Text;
        spvDetails: Text;
        financialTerms: Text;
        creationDate: Int;
        numTokens: Nat;
        accumulatedIncome: Nat;
        account: Account; // Account for the collection to hold assets directly
    };

    public type TransferArgs = {
        from: Account;
        to: Account;
        token_ids: [TokenId];
        memo: ?Blob;
        created_at_time: ?Nat64;
        is_atomic: ?Bool;
    };

    public type Approval = {
        owner: Account;
        approved: Account;
        tokenId: TokenId;
    };

    public type ApprovalArgs = {
        owner: Account;
        spender: Principal;
        token_ids: [TokenId];
        expires_at: ?Nat64;
        memo: ?Blob;
        created_at_time: ?Nat64;
    };

    public type Error = {
        #Unauthorized;
        #InvalidInput;
        #TokenNotFound;
        #InternalError;
        #CollectionFrozen;
        #CollectionNotFound;
        #TokenAlreadyExists;
    };

    public type TransferError = Error;
    public type ApprovalError = Error;

    func accountEqual(x: Account, y: Account): Bool {
        return x.owner == y.owner and x.subaccount == y.subaccount;
    };

    func accountHash(x: Account): Hash {
        return Principal.hash(x.owner);
    };

    func hash(n: Nat): Nat32 {
        return Blob.hash(Text.encodeUtf8(Nat.toText(n)));
    };

    func deriveSubaccount(collectionId: CollectionId): Blob {
        let len : Nat = 32;
        let ith_byte = func(i : Nat) : Nat8 {
            assert(i < len);
            let shift : Nat = 8 * (len - 1 - i);
            Nat8.fromIntWrap(collectionId / 2**shift)
        };
        return Blob.fromArray(Array.tabulate<Nat8>(len, ith_byte));
    };

    stable var nextTokenId: TokenId = 0;
    stable var nextCollectionId: CollectionId = 1;

    private var tokens: HashMap.HashMap<TokenId, Token> = HashMap.HashMap<TokenId, Token>(0, Nat.equal, hash);
    private var ownerTokens: HashMap.HashMap<Account, [TokenId]> = HashMap.HashMap<Account, [TokenId]>(0, accountEqual, accountHash);
    private var transactions: HashMap.HashMap<TokenId, [Transaction]> = HashMap.HashMap<TokenId, [Transaction]>(0, Nat.equal, hash);
    private var collections: HashMap.HashMap<CollectionId, Collection> = HashMap.HashMap<CollectionId, Collection>(0, Nat.equal, hash);
    private var frozenCollections: HashMap.HashMap<CollectionId, Bool> = HashMap.HashMap<CollectionId, Bool>(0, Nat.equal, hash);
    private stable var approvals: [Approval] = [];

    let admin: Principal = Principal.fromText("xgewh-5qaaa-aaaas-aaa3q-cai");

    

    // Function to log transactions
    func logTransaction(action: TransactionTypes, tokenId: TokenId, from: ?Account, to: ?Account): () {
        let transaction: Transaction = {
            id = transactions.size();
            action = action;
            tokenId = tokenId;
            from = from;
            to = to;
            timestamp = Time.now();
        };
        let currentTransactions = Option.get(transactions.get(tokenId), []);
        transactions.put(tokenId, Array.append(currentTransactions, [transaction]));
    };

    // Simplified Metadata Validation
    func validateMetadata(metadata: Metadata): Result<(), Error> {
        if (metadata.name == "" or metadata.image == "") {
            return #err(#InvalidInput);
        };
        return #ok(());
    };

    public shared ({caller}) func isApproved(owner: Account, tokenId: TokenId): async Bool {
        let exchangeCanister = Principal.fromText("wcjzv-eqaaa-aaaas-aaa5q-cai");

        for (approval in approvals.vals()) {
            if ((accountEqual(approval.owner, owner) and approval.tokenId == tokenId and (approval.approved.owner == caller or approval.approved.owner == exchangeCanister))) {
                return true;
            }
        };

        return false;
    };

    // Function to create a new collection and mint 1000 NFTs
    public shared ({caller}) func createCollectionAndMint(name: Text, description: Text, image: Text, spvDetails: Text, financialTerms: Text): async Result<CollectionId, Error> {
        if (Principal.notEqual(admin, caller)) {
            return #err(#Unauthorized);
        };

        let collectionId = nextCollectionId;
        nextCollectionId += 1;

        let account: Account = {
            owner = Principal.fromText("wlksj-syaaa-aaaas-aaa4a-cai");
            subaccount = ?deriveSubaccount(collectionId);
        };

        let collection: Collection = {
            name = name;
            description = description;
            spvDetails = spvDetails;
            financialTerms = financialTerms;
            creationDate = Time.now();
            numTokens = 1000;  // Fixed supply for now
            accumulatedIncome = 0;
            account = account;  // Assign the generated account
        };

        collections.put(collectionId, collection);
        frozenCollections.put(collectionId, false);  // Initialize collection as not frozen

        let owner: Account = { owner = caller; subaccount = null };

        for (i in Iter.range(0, 999)) {
            let metadata: Metadata = {
                name = name # " #" # Nat.toText(i + 1);
                description = description;
                image = image;
                creator = caller;
                creationDate = collection.creationDate;
                attributes = [];
                collectionId = collectionId;
                fractionalOwnership = 1;  // Each NFT represents 0.1%
                spvDetails = spvDetails;
                financialTerms = financialTerms;
            };

            switch (validateMetadata(metadata)) {
                case (#err(e)) { return #err(e); };
                case (#ok(())) {};
            };

            let tokenId = nextTokenId;
            nextTokenId += 1;

            if (Option.isSome(tokens.get(tokenId))) {
                return #err(#TokenAlreadyExists);
            };

            let token: Token = {
                id = tokenId;
                owner = owner;
                metadata = metadata;
            };

            tokens.put(tokenId, token);

            let ownerTokenList = switch (ownerTokens.get(owner)) {
                case (null) { [tokenId] };
                case (?ids) { Array.append(ids, [tokenId]) };
            };

            ownerTokens.put(owner, ownerTokenList);

            logTransaction(#Mint, tokenId, null, ?owner);
        };

        return #ok(collectionId);
    };

    // Function to freeze all NFTs in a specific collection
    public shared ({caller}) func freezeCollection(collectionId: CollectionId): async Result<Bool, Error> {
        if (Principal.notEqual(admin, caller)) {
            return #err(#Unauthorized);
        };

        let collection = collections.get(collectionId);
        if (Option.isNull(collection)) {
            return #err(#CollectionNotFound);
        };

        frozenCollections.put(collectionId, true);  // Mark collection as frozen
        return #ok(true);
    };

    // Function to unfreeze all NFTs in a specific collection
    public shared ({caller}) func unfreezeCollection(collectionId: CollectionId): async Result<Bool, Error> {
        if (Principal.notEqual(admin, caller)) {
            return #err(#Unauthorized);
        };

        let collection = collections.get(collectionId);
        if (Option.isNull(collection)) {
            return #err(#CollectionNotFound);
        };

        frozenCollections.put(collectionId, false);  // Mark collection as not frozen
        return #ok(true);
    };

    // Function to list all unique owners of a given collection
    public query func listCollectionOwners(collectionId: CollectionId): async Result<[Account], Error> {
        let collection = collections.get(collectionId);
        if (Option.isNull(collection)) {
            return #err(#CollectionNotFound);
        };

        var owners: [Account] = [];
        let seenOwners: HashMap.HashMap<Principal, Bool> = HashMap.HashMap<Principal, Bool>(0, Principal.equal, Principal.hash);

        for ((_, token) in tokens.entries()) {
            if (token.metadata.collectionId == collectionId) {
                if (Option.isNull(seenOwners.get(token.owner.owner))) {
                    owners := Array.append(owners, [token.owner]);
                    seenOwners.put(token.owner.owner, true);
                }
            }
        };

        return #ok(owners);
    };

    // Function to calculate the total ownership percentage for a given account
    public query func getTotalOwnership(account: Account): async Nat {
        let tokensOwned = switch (ownerTokens.get(account)) {
            case (null) { return 0; };
            case (?ids) { return ids.size(); };
        };
        return tokensOwned; // Directly returns the number of tokens
    };

    // ICRC-7: Transfer function with simplified whitelist and KYC logic
    public shared ({caller}) func icrc7_transfer(args: TransferArgs): async Result<Nat, TransferError> {
        for (tokenId in args.token_ids.vals()) {
            let token = tokens.get(tokenId);
            switch(token){
                case(null){
                    return #err(#InvalidInput);
                    };
                case(? actualToken){
                    let isFrozen = frozenCollections.get(actualToken.metadata.collectionId);
                    if (Option.get(isFrozen, false)) {
                        return #err(#CollectionFrozen);
                    };

                    // Simplified: Always true in MVP
                    if (not isAccountWhitelisted(args.to) or not isAccountKYCApproved(args.to)) {
                        return #err(#Unauthorized);
                    };

                    if (caller != actualToken.owner.owner and not (await isApproved(actualToken.owner, tokenId))) {
                        return #err(#Unauthorized);
                    };

                    try {
                        tokens.put(tokenId, { actualToken with owner = args.to });

                        let fromOwnerTokenList = switch (ownerTokens.get(actualToken.owner)) {
                            case (null) { [] };
                            case (?ids) { Array.filter<Nat>(ids, func(id: Nat): Bool { id != tokenId }) };
                        };
                        ownerTokens.put(actualToken.owner, fromOwnerTokenList);

                        let toOwnerTokenList = switch (ownerTokens.get(args.to)) {
                            case (null) { [tokenId] };
                            case (?ids) { Array.append(ids, [tokenId]) };
                        };
                        ownerTokens.put(args.to, toOwnerTokenList);

                        logTransaction(#Transfer, tokenId, ?actualToken.owner, ?args.to);
                    } catch (_) {
                        return #err(#InternalError);
                    };
        };

                }
            };

            //let actualToken = Option.get(token);

                    return #ok(args.token_ids.size());
    };

    // Example whitelist check (placeholder)
    private func isAccountWhitelisted(account: Account): Bool {
        // Placeholder for whitelist logic, currently always returns true
        return true;
    };

    // Example KYC check (placeholder)
    private func isAccountKYCApproved(account: Account): Bool {
        // Placeholder for KYC logic, currently always returns true
        return true;
    };

    // ICRC-7: Metadata function
    public query func icrc7_metadata(token_id: TokenId): async Result<Metadata, Error> {
        switch (tokens.get(token_id)) {
            case (null) { return #err(#TokenNotFound); };
            case (?token) { return #ok(token.metadata); };
        }
    };

    // ICRC-7: Owner of function
    public query func icrc7_owner_of(token_id: TokenId): async Result<Account, Error> {
        switch (tokens.get(token_id)) {
            case (null) { return #err(#TokenNotFound); };
            case (?token) { return #ok(token.owner); };
        }
    };

    // ICRC-7: Balance of function
    public query func icrc7_balance_of(account: Account): async Nat {
        switch (ownerTokens.get(account)) {
            case (null) { return 0; };
            case (?ids) { return ids.size(); };
        }
    };

    // ICRC-7: Tokens of function
    public query func icrc7_tokens_of(account: Account): async [TokenId] {
        switch (ownerTokens.get(account)) {
            case (null) { return []; };
            case (?ids) { return ids; };
        }
    };

    // ICRC-7: Supported standards function
    public query func icrc7_supported_standards(): async [{ name: Text; url: Text }] {
        return [
            { name = "ICRC-7"; url = "https://github.com/dfinity/ICRC" },
        ];
    };

    // Function to view the balance of tokens held by a collection
    public query func getCollectionBalance(collectionId: CollectionId): async Nat {
        let collectionOpt = collections.get(collectionId);
        switch(collectionOpt){
            case(null){
                return 0;
            };
            case(? collection){
                //incorrect implementation
                return 1;
            }
        }
    };

    // Function to send tokens from the collection's account
    //public shared ({caller}) func sendTokens(collectionId: CollectionId, to: Account, amount: Nat): async Result<(), Error> {
    //    let collectionOpt = collections.get(collectionId);
    //    switch(collectionOpt){
    //        case(null){
    //            return #err(#CollectionNotFound);
    //        };
    //        case(? collection){
    //    if (not isAuthorized(caller, collectionId)) {
    //        return #err(#Unauthorized);
    //    };
//
    //    // Interact with the ledger or token canister to transfer the tokens
    //    await icrc1_transfer({
    //        from = { owner = collection.account.owner; subaccount = collection.account.subaccount };
    //        to = to;
    //        amount = amount
    //    });
//
    //    return #ok(());
    //        }
    //    }
   


        // Ensure only authorized actions can perform transfers
   // };

    // Function to check if the caller is authorized to manage tokens on behalf of the collection
    public func isAuthorized(caller: Principal, collectionId: CollectionId): async Bool {
        // Implement your authorization logic here, e.g., based on governance rules
        // For example, checking if the caller has sufficient tokens in the collection to perform the action
        return true; // Placeholder
    }
}
