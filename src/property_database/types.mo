import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Text "mo:base/Text";

module {
    //public type HashMap.HashMap<A,B> = HashMap.HashMap<A,B>;
    // Main Property Structure
    public type Property = {
        id: Nat;  // Unique identifier for the property
        details: PropertyDetails;  // Grouped details about the property, including description
        financials: Financials;  // Financial details, including investment, valuation, and income
        invoices : Invoices;
        collection: Collection;  // Grouped NFTs, metadata, and property status
        administrative: AdministrativeInfo;  // Grouped administrative information
        operational: OperationalInfo;  // Grouped operational information
        governance: Governance;  // Governance structure for managing proposals and votes
    };

    // PropertyDetails Structure
    public type PropertyDetails = {
        location: LocationDetails;  // Location-specific details, including property name
        physical: PhysicalDetails;  // Physical characteristics of the property
        additional: AdditionalDetails;  // Additional property-related details
        description: Text;  // General description of the property
    };

    public type LocationDetails = {
        name: Text;  // Name of the property
        addressLine1: Text;  // Street address
        location: Text;  // City, state, or other location information
        postcode: Text;  // Postal code
    };

    public type PhysicalDetails = {
        lastRenovation: Nat;
        yearBuilt: Nat;
        squareFootage: Nat;
        beds: Nat;
        baths: Nat;
    };

    public type AdditionalDetails = {
        crimeScore: Nat;
        schoolScore: Nat;
        affordability: Nat;
        floodZone: Bool;
    };

    // Financials Structure
    public type Financials = {
        investment: InvestmentDetails;  // Separate structure for investment-related details
        currentValue: Nat;  // Current market value of the property
        pricePerSqFoot: Nat;  // Price per square foot of the property
        valuations: [ValuationRecord];  // Array of property valuation records
        monthlyRent: Nat;  // Monthly rent collected from the property
        yield: Float;  // Yield based on rental income
    };

    public type InvestmentDetails = {
        totalInvestmentValue: Nat;
        platformFee: Nat;
        initialMaintenanceReserve: Nat;
        purchasePrice: Nat;
    };

    public type Invoices = {
        id : Nat;
        invoice : [(Nat, Invoice)];
    };
    
    
    // Updated Invoice structure
    public type Invoice = {
        invoiceId: Nat;  // Unique identifier for the invoice
        proposalId: Nat;  // Linked to a DAO proposal for approval
        amount: Nat;  // Amount of the invoice
        dateIssued: Int;  // Date the invoice was issued
        dueDate: Int;  // Due date for payment
        datePaid: ?Int;  // Optional field for when the invoice is paid
        category: InvoiceCategory;  // Unified category with both type and category
        paymentType: PaymentMethod;  // How the payment is made (e.g., Crypto, Bank Transfer, etc.)
        status: InvoiceStatus;  // Status of the invoice (Pending, Approved, Paid)
        vendor: Text;  // Vendor or recipient for the payment (for expenses)
        description: Text;  // Description of the invoice or service
    };

    public type InvoiceCategory = {
        #Rent;  // Income: Rent collected
        #MaintenanceTaxExempt;  // Expense: Maintenance costs
        #MaintenanceNonTaxExempt;  // Expense: Maintenance costs
        #Utilities;  // Expense: Utility bills
        #Insurance;  // Expense: Insurance payments
        #OtherIncome: Text;  // Other types of income, custom description allowed
        #OtherExpense: Text;  // Other types of expenses, custom description allowed
    };

    // Define the status of an invoice (pending, approved, paid)
    public type InvoiceStatus = {
        #Pending;  // Waiting for approval by DAO
        #Approved;  // Approved by DAO, ready to be paid
        #Rejected; //Rejected by DAO, won't be paid
        #Paid;  // Payment has been completed
    };

    // Define the PaymentMethod structure for how the payment was made
    public type PaymentMethod = {
        #Crypto;
        #HGB;
        #BankTransfer;
        #Cash;
        #Other: Text;  // Option to define other payment methods
    };


    // Collection Structure
    public type Collection = {
        nfts: [NFT];  // Array of NFTs associated with the property
        metadata: Metadata;  // Shared metadata for the property and its NFTs
        status: PropertyStatus;  // Property status with different possible states
        account: Account; //The collections joint assets e.g. maintenance fund
    };

    public type PropertyStatus = {
        #PreCompletion;
        #Active;
        #Frozen;
        #Selling;
        #Other;  // Add any other relevant statuses as needed
    };

    // AdministrativeInfo Structure
    public type AdministrativeInfo = {
        documentId: Nat;
        
        insurance: [(Nat, InsurancePolicy)];  // Insurance policies
        documents: [(Nat, Document)];  // Property-related documents
        notes: [(Nat, Note)];  // General notes related to the property
    };

    // OperationalInfo Structure
    public type OperationalInfo = {
        tenants: [(Nat, Tenant)];  // Tenants in the property
        maintenance: [(Nat, MaintenanceRecord)];  // Maintenance tasks
        inspections: [(Nat, InspectionRecord)];  // Inspection records
    };

    //Governance Structure
    public type Governance = {
        proposalId : Nat;
        proposals : [(Nat, Proposal)]
    };

    // Proposal Structure
    public type Proposal = {
        id: Nat;  // Unique identifier for the proposal
        title: Text;  // Title of the proposal
        description: Text;  // Description of the proposal
        tally: Int;  // Single tally for votes (increments for yes, decrements for no)
        endTime: Int;  // Timestamp indicating when the voting period ends
        executed: Bool;  // Indicates if the proposal has been executed
        eligibleToVote : [Principal]; //Stores all principals that haven't yet voted on a proposal that did hold the NFT at the time of voting
        votes: [(Principal, Bool)];  // Mapping of voter to their vote (true for yes, false for no)
    };

    // Supporting Structures

    // InsurancePolicy Structure
    public type InsurancePolicy = {
        id: Nat;  // Unique identifier for the insurance policy
        policyNumber: Text;  // Unique policy number
        provider: Text;  // Insurance provider
        startDate: Int;  // Start date of the policy
        endDate: ?Int;  // End date of the policy (None if active)
        premium: Nat;  // Premium cost
        paymentFrequency: PaymentFrequency;  // Whether paid weekly, monthly, or annually
        nextPaymentDate: Int;  // Date of the next payment
        contactInfo: Text;  // Contact information for the insurance provider
    };

    public type PaymentFrequency = {
        #Weekly;
        #Monthly;
        #Annually;
    };

    // Document Structure
    public type Document = {
        id: Nat;  // Unique identifier for the document
        title: Text;  // Title of the document
        description: Text;  // Description or purpose of the document
        documentType: DocumentType;  // Type of document, e.g., "Lease", "Inspection Report"
        uploadDate: Int;  // Date the document was uploaded or created
        url: Text;  // URL or file location where the document is stored
    };

    //Document type 
    public type DocumentType = {
        #AST;
        #EPC;
        //etc
        #Other : Text;
    };

    // InspectionRecord Structure
    public type InspectionRecord = {
        id: Nat;  // Unique identifier for the inspection record
        inspectorName: Text;  // Name of the inspector or inspection company
        date: Int;  // Date of the inspection
        findings: Text;  // Findings from the inspection
        actionRequired: ?Text;  // Description of any required follow-up actions
        followUpDate: ?Int;  // Date for a follow-up inspection, if needed
    };

    // ValuationRecord Structure
    public type ValuationRecord = {
        id: Nat;  // Unique identifier for the valuation record
        date: Int;  // Date of the valuation
        value: Nat;  // Assessed value of the property
        method: ValuationMethod;  // Method used for the valuation
        appraiser: Principal;  // Name of the appraiser or firm that conducted the valuation
    };

    public type ValuationMethod = {
        #Appraisal;
        #MarketComparison;
        #Online;
    };

    // Note Structure
    public type Note = {
        id: Nat;  // Unique identifier for the note
        date: Int;  // Date the note was made
        content: Text;  // Content of the note
        author: Text;  // Name of the person who made the note
    };

    // Tenant Structure
    public type Tenant = {
        id: Nat;  // Unique identifier for the tenant
        leadTenant: Text;  // Name of the lead tenant
        otherTenants: [Text];  // Array of names of other tenants
        principal: ?Principal;  // Lead tenant's Principal (for interactions/payments), nullable
        monthlyRent: Nat;  // Amount of rent the tenant pays monthly
        securityDeposit: Nat;  // Security deposit amount
        paymentHistory: [Payment];  // Array of payments made by the tenant
        leaseStartDate: Int;  // Start date of the lease
        leaseEndDate: ?Int;  // End date of the lease (None if currently active)
    };

    // MaintenanceRecord Structure
    public type MaintenanceRecord = {
        id: Nat;  // Unique identifier for the maintenance record
        description: Text;  // Description of the maintenance task or issue
        dateReported: Int;  // The date the issue was reported or the task was created
        dateCompleted: ?Int;  // The date the task was completed (None if still ongoing)
        cost: ?Nat;  // The cost of the maintenance, if applicable
        contractor: ?Text;  // The name of the contractor or company responsible, if applicable
        status: MaintenanceStatus;  // Status of the maintenance task (e.g., Pending, In Progress, Completed)
        paymentMethod: PaymentMethod;  // Method used to pay for the maintenance
    };

    public type MaintenanceStatus = {
        #Pending;
        #InProgress;
        #Completed;
    };
    
    public type Payment = {
        id: Nat;  // Unique identifier for the payment
        amount: Nat;  // Amount paid
        date: Int;  // Date of the payment
        method: PaymentMethod;  // Method used for the payment
    };

    // Account Structure
    public type Account = {
        owner: Principal;
        subaccount: ?Blob;
    };

    // NFT and Metadata Structures
    public type NFT = {
        id: Nat;  // Unique identifier for the NFT
        propertyId: Nat;  // Reference to the parent property
        owner: Principal;
        fractionalOwnership: Nat;  // Represents 0.1% ownership
        metadata: Metadata;  // Embedded metadata from the property
        currentValue: Nat;  // Current value of the NFT
    };

    public type Metadata = {
        name: Text;
        description: Text;
        image: Text;  // URL to the image
        creator: Principal;
        spvDetails: Text;  // SPV registration details or a link to the document
        financialTerms: Text;  // Financial terms like dividend policies
        creationDate: Int;  // Date the NFT was created
    };
}