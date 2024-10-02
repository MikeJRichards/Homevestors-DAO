import Types "./types";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Hash "mo:base/Hash";
import Principal "mo:base/Principal";
import Float "mo:base/Float";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Option "mo:base/Option";

actor {
    public type Result<A,B> = Result.Result<A,B>;
    // Aliasing each type for direct use in your actor
    public type Property            =      Types.Property;
    public type PropertyDetails     =      Types.PropertyDetails;
    public type LocationDetails     =      Types.LocationDetails;
    public type PhysicalDetails     =      Types.PhysicalDetails;
    public type AdditionalDetails   =      Types.AdditionalDetails;
    public type Financials          =      Types.Financials;
    public type InvestmentDetails   =      Types.InvestmentDetails;
    public type Collection          =      Types.Collection;
    public type PropertyStatus      =      Types.PropertyStatus;
    public type AdministrativeInfo  =      Types.AdministrativeInfo;
    public type InsurancePolicy     =      Types.InsurancePolicy;
    public type PaymentFrequency    =      Types.PaymentFrequency;
    public type Document            =      Types.Document;
    public type InspectionRecord    =      Types.InspectionRecord;
    public type ValuationRecord     =      Types.ValuationRecord;
    public type ValuationMethod     =      Types.ValuationMethod;
    public type Note                =      Types.Note;
    public type Tenant              =      Types.Tenant;
    public type Payment             =      Types.Payment;
    public type PaymentMethod       =      Types.PaymentMethod;
    public type MaintenanceRecord   =      Types.MaintenanceRecord;
    public type MaintenanceStatus   =      Types.MaintenanceStatus;
    public type Account             =      Types.Account;
    public type NFT                 =      Types.NFT;
    public type Metadata            =      Types.Metadata;
    public type Governance          =      Types.Governance;
    public type Proposal            =      Types.Proposal;
    public type OperationalInfo     =      Types.OperationalInfo;
    public type Invoices            =      Types.Invoices;
    public type Invoice             =      Types.Invoice;
    public type InvoiceCategory     =      Types.InvoiceCategory;
    public type InvoiceStatus       =      Types.InvoiceStatus;

func natToHash (nat : Nat): Hash.Hash {
    return Text.hash(Nat.toText(nat));
};

func accountEqual(x: Account, y: Account): Bool {
        return x.owner == y.owner and x.subaccount == y.subaccount;
};

func accountHash(x: Account): Hash.Hash {
        return Principal.hash(x.owner);    
};

func deriveSubaccount(collectionId: Nat): Blob {
        let len : Nat = 32;
        let ith_byte = func(i : Nat) : Nat8 {
            assert(i < len);
            let shift : Nat = 8 * (len - 1 - i);
            Nat8.fromIntWrap(collectionId / 2**shift)
        };
        return Blob.fromArray(Array.tabulate<Nat8>(len, ith_byte));
};


//private var nftsMap: HashMap.HashMap<Account, NFT> = HashMap.HashMap<Account, NFT>(0, accountEqual, accountHash);
//private var nextNFTId: Nat = 0;
private var properties: HashMap.HashMap<Nat, Property> = HashMap.HashMap<Nat, Property>(0, Nat.equal, natToHash);
var nextPropertyId : Nat = 0;


public func createProperty(
    details: PropertyDetails,
    investment: InvestmentDetails,
    monthlyRent : Nat,
    metadata: Metadata,
): async Nat {
    // Generate a new unique ID for the property
    let propertyId = nextPropertyId;
    nextPropertyId += 1;

    let financials : Financials = {
        investment;
        currentValue = investment.purchasePrice;
        pricePerSqFoot = Nat.div(investment.purchasePrice, details.physical.squareFootage);
        valuations = [];
        monthlyRent;
        yield = Float.fromInt(Nat.div(monthlyRent, investment.purchasePrice));
    };

    let collection : Collection = {
        nfts = [];
        metadata;
        status = #PreCompletion;
        account = {owner = Principal.fromText("be2us-64aaa-aaaaa-qaabq-cai"); subaccount = ?deriveSubaccount(propertyId)};
    };

    let administrative : AdministrativeInfo = {
        documentId = 0;
        insurance = [];
        documents = [];
        notes = [];
    };

    let operational : OperationalInfo = {
        tenants = [];
        maintenance = [];
        inspections = [];
    };

    let invoices : Invoices = {
        id = 0;
        invoice = [];
    };

    let governance : Governance = {
        proposalId = 0;
        proposals = [];
    };

    // Create the new Property
    let newProperty: Property = {
        id = propertyId;
        details;
        financials;
        collection;
        administrative;
        invoices;
        operational;
        governance;
    };

    // Store the Property in the global propertiesMap
    properties.put(propertyId, newProperty);

    // Return the ID of the newly created property
    return propertyId;
};

public func updateProperty(
    propertyId: Nat,
    newDetails: ?PropertyDetails,
    newFinancials: ?Financials,
    newInvoices: ?Invoices,
    newCollection: ?Collection,
    newAdministrative: ?AdministrativeInfo,
    newOperational: ?OperationalInfo,
    newGovernance: ?Governance
): async Result<(), Text> {
    // Retrieve the property by its ID
    switch (properties.get(propertyId)) {
        case (?property) {
                let details = switch (newDetails) {
                    case (null) { property.details };
                    case (?value) { value };
                };
                let financials = switch (newFinancials) {
                    case (null) { property.financials };
                    case (?value) { value };
                };
                let invoices = switch (newInvoices) {
                    case (null) { property.invoices };
                    case (?value) { value };
                };
                let collection = switch (newCollection) {
                    case (null) { property.collection };
                    case (?value) { value };
                };
                let administrative = switch (newAdministrative) {
                    case (null) { property.administrative };
                    case (?value) { value };
                };
                let operational = switch (newOperational) {
                    case (null) { property.operational };
                    case (?value) { value };
                };
                let governance = switch (newGovernance) {
                    case (null) { property.governance };
                    case (?value) { value };
                };
            let updatedProperty: Property = {
                id = propertyId;
                details;
                financials;
                collection;
                invoices;
                administrative;
                operational;
                governance;
            };
            
            // Update the property in the HashMap
            properties.put(propertyId, updatedProperty);
            
            return #ok(());
        };
        case (null) {
            return #err("Property not found.");
        };
    };
};

public func updatePropertyDescription( propertyId: Nat, newDescription: Text): async Result<(), Text> {
    switch (properties.get(propertyId)) {
        case (?property) {
            let updatedDetails : PropertyDetails = {
                property.details with
                description = newDescription;
            };
            let updatedProperty : Property= { 
                property with 
                details = updatedDetails;
             };
            properties.put(propertyId, updatedProperty);
            return #ok(());
        };
        case (null) {
            return #err("Property not found.");
        };
    };
};
//Need to still check to see if updating current value should impact any other fields
public shared ({ caller }) func updatePropertyCurrentValue(propertyId: Nat, newValue: Nat, valuationDate: Int, valuationMethod: ValuationMethod): async Result<(), Text> {
    switch (properties.get(propertyId)) {
        case (?property) {
            let financials = property.financials;

            // Calculate new price per square foot and yield
            let updatedPricePerSqFoot = newValue / property.details.physical.squareFootage;
            let updatedYield : Float = Float.fromInt(Nat.div(Nat.mul(financials.monthlyRent, 12), newValue));

            // Create a new valuation record
            let newValuation: [ValuationRecord] = [{
                id = Nat.add(Array.size(financials.valuations), 1);
                date = Time.now();
                value = newValue;
                method = valuationMethod;
                appraiser = caller;
            }];

            let updatedFinancials : Financials = {
                financials with 
                currentValue = newValue;
                pricePerSqFoot = updatedPricePerSqFoot;
                valuations = Array.append<ValuationRecord>(newValuation, financials.valuations);
                yeild = updatedYield;
            };

            let updatedProperty : Property = {
                property with 
                financials = updatedFinancials;
            };

            properties.put(propertyId, updatedProperty);
            return #ok(());
        };
        case (null) {
            return #err("Property not found.");
        };
    }
};
//need to check that changing the rent doesn't influence other aspects of property other than financials
public func updatePropertyMonthlyRent(propertyId: Nat, updatedRent: Nat): async Result<(), Text> {
    switch (properties.get(propertyId)) {
        case (?property) {
            let financials = property.financials;

            // Recalculate yield
            let updatedYield = Float.fromInt(Nat.div(Nat.mul(updatedRent, 12),financials.currentValue));

            let updatedFinancials : Financials = {
                financials with
                monthlyRent = updatedRent;
                yield = updatedYield;
            };

            let updatedProperty : Property = { 
                property with 
                financials = updatedFinancials 
            };
            properties.put(propertyId, updatedProperty);
            return #ok(());
        };
        case (null) {
            return #err("Property not found.");
        };
    }
};

public func updatePropertyStatus(
    propertyId: Nat,
    newStatus: PropertyStatus
): async Result<(), Text> {
    switch (properties.get(propertyId)) {
        case (?property) {
            let updatedCollection : Collection = { property.collection with status = newStatus };
            let updatedProperty : Property = { property with collection = updatedCollection };
            properties.put(propertyId, updatedProperty);
            return #ok(());
        };
        case (null) {
            return #err("Property not found.");
        };
    }
}; 


//This code onwards needs to be written more succintly. Essentially its all doing a very similar task but is almost 300 lines of code - very repetitive
//The task - CRUD functionality - create, read, update and ?delete
//For Read:
//given property return something with this id from this given tuple
//helper functions - get property,

func findPropertyById(propertyId: Nat): Property {
    switch (properties.get(propertyId)) {
        case (?property) {
            return property;  // Property found, return it
        };
        case null {
            Debug.trap("Property with id " # Nat.toText(propertyId) # " not found.");
        };
    }
};

func findValueByKey<T>(tuples: [(Nat, T)], key: Nat): T {
    for ((k, v) in tuples.vals()) {
        if (k == key) {
            return v;  // Return the value if the key matches
        };
    };
    Debug.trap("Key " # Nat.toText(key) # " not found in this property.");
};

func addElementToArray<T>(array: [(Nat, T)], currentId: Nat, newElement: T): [(Nat, T)] {
    return Array.append(array, [(currentId, newElement)]);
};

func updateElementInArray<T>(array :[(Nat, T)], newElement: T, id: Nat): [(Nat, T)]{
    let map : HashMap.HashMap<Nat, T> = HashMap.fromIter<Nat, T>(array.vals(), array.size(), Nat.equal, natToHash);
    switch(map.get(id)){
        case null {
            Debug.trap("The id doesn't exist")
        };
        case(_){
            map.put(id, newElement);
        };  
    };
    return Iter.toArray(map.entries());
};

func removeElementInArray<T>(array:[(Nat,T)], id: Nat): [(Nat, T)]{
    let newArray : [(Nat, T)] = Array.filter(array, func((ids: Nat, _: T)) : Bool {
        id != ids
    });
    assert(newArray.size() != array.size());
    return newArray;
};

func updatePropertyField<T>(
    propertyId: Nat,
    updateFunc: Property -> Property
): async () {
    let property = findPropertyById(propertyId);
    let updatedProperty = updateFunc(property);
    properties.put(propertyId, updatedProperty);
};






//Now a helper function that returns from an array tuple that retrieves a specific value from a key nat

public func getDocument(propertyId: Nat, documentId : Nat): async Document {
    let property = findPropertyById(propertyId);
    return findValueByKey(property.administrative.documents, documentId)

};

public func addDocument(propertyId: Nat, newDocument: Document): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedAdministrative = {
            property.administrative with 
            documents = addElementToArray(property.administrative.documents, property.administrative.documentId, newDocument);
            documentId = property.administrative.documentId + 1;
        };        
        return { property with administrative = updatedAdministrative };
    });
};

public func updateDocumentById(propertyId: Nat, updatedDocument: Document, id: Nat): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedAdministrative = {
            property.administrative with 
            documents = updateElementInArray(property.administrative.documents, updatedDocument, id);
        };        
        return { property with administrative = updatedAdministrative };
    });
};

public func removeDocumentById(propertyId: Nat, id: Nat): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedAdministrative = {
            property.administrative with 
            documents = removeElementInArray(property.administrative.documents, id);
        };        
        return { property with administrative = updatedAdministrative };
    });
};

public func getInsurancePolicy(propertyId: Nat, documentId : Nat): async Document {
    let property = findPropertyById(propertyId);
    return findValueByKey(property.administrative.documents, documentId)

};

public func addInsurancePolicy(propertyId: Nat, newPolicy: Document): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedAdministrative = {
            property.administrative with 
            insurance = addElementToArray(property.administrative.insurance, property.administrative.insuranceId, newPolicy);
            insuranceId = property.administrative.insuranceId + 1;
        };        
        return { property with administrative = updatedAdministrative };
    });
};

public func updateDocumentById(propertyId: Nat, updatedDocument: Document, id: Nat): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedAdministrative = {
            property.administrative with 
            documents = updateElementInArray(property.administrative.documents, updatedDocument, id);
        };        
        return { property with administrative = updatedAdministrative };
    });
};

public func removeDocumentById(propertyId: Nat, id: Nat): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedAdministrative = {
            property.administrative with 
            documents = removeElementInArray(property.administrative.documents, id);
        };        
        return { property with administrative = updatedAdministrative };
    });
};
//Below this - needs rewriting
public func addInsurancePolicy(propertyId: Nat, policy: InsurancePolicy): async Result<(), Text> {
    switch (properties.get(propertyId)) {
        case (?property) {
            let newPolicy : InsurancePolicy = {policy with id = property.administrative.insurance.size()};
            let updatedInsurance = Array.append(property.administrative.insurance, [(newPolicy.id, newPolicy)]);
            let updatedAdmin : AdministrativeInfo = {property.administrative with insurance = updatedInsurance };
            let updatedProperty : Property = { property with administrative = updatedAdmin };
            properties.put(propertyId, updatedProperty);
            return #ok(());
        };
        case (null) {
            return #err("Property not found.");
        };
    }
};

public func editInsurancePolicy(propertyId: Nat, policy: InsurancePolicy, policyId : Nat): async Result<(), Text> {
    switch (properties.get(propertyId)) {
        case(?property){
            let policies = property.administrative.insurance;
            let policiesMap : HashMap.HashMap<Nat,InsurancePolicy> = HashMap.fromIter<Nat, InsurancePolicy>(policies.vals(), policies.size(), Nat.equal, natToHash);
            switch(policiesMap.get(propertyId)){
                case(null){
                    return #err("insurance policy not found.");
                };
                case(_){
                    policiesMap.put(policyId, policy);
                    let policiesArray : [(Nat, InsurancePolicy)] = Iter.toArray(policiesMap.entries());
                    let updatedAdmin = { property.administrative with insurance = policiesArray };
                    let updatedProperty : Property = { property with administrative = updatedAdmin };
                    properties.put(propertyId, updatedProperty);
                    return #ok(());
                };
            }
        };
        case (null) {
            return #err("Property not found.");
        };
    }
};

public func addNote(propertyId: Nat, note: Note): async Result<(), Text> {
    switch (properties.get(propertyId)) {
        case (?property) {
            let newNote : Note = {note with id = property.administrative.notes.size()};
            let updatedNotes = Array.append(property.administrative.notes, [(newNote.id, newNote)]);
            let updatedAdmin : AdministrativeInfo  = { property.administrative with notes = updatedNotes };
            let updatedProperty : Property = { property with administrative = updatedAdmin };
            properties.put(propertyId, updatedProperty);
            return #ok(());
        };
        case (null) {
            return #err("Property not found.");
        };
    }
}; 

public func editNote(propertyId: Nat, note: Note, noteId: Nat): async Result<(), Text> {
    switch (properties.get(propertyId)) {
        case(?property) {
            let notes = property.administrative.notes;
            let notesMap: HashMap.HashMap<Nat, Note> = HashMap.fromIter<Nat, Note>(notes.vals(), notes.size(), Nat.equal, natToHash);
            
            switch (notesMap.get(noteId)) {
                case (null) {
                    return #err("Note not found.");
                };
                case (_) {
                    notesMap.put(noteId, note);
                    let notesArray: [(Nat, Note)] = Iter.toArray(notesMap.entries());
                    let updatedAdmin : AdministrativeInfo= { property.administrative with notes = notesArray };
                    let updatedProperty : Property = { property with administrative = updatedAdmin };
                    properties.put(propertyId, updatedProperty);
                    return #ok(());
                };
            }
        };
        case (null) {
            return #err("Property not found.");
        };
    }
};

public func addInspectionRecord(propertyId: Nat, record: InspectionRecord): async Result<(), Text> {
    switch (properties.get(propertyId)) {
        case(?property) {
            let newRecord : InspectionRecord = {record with id = property.operational.inspections.size()};
            let inspections = Array.append(property.operational.inspections, [(newRecord.id, newRecord)]);
            let updatedOperational : OperationalInfo = { property.operational with inspections = inspections };
            let updatedProperty: Property = { property with operational = updatedOperational };
            properties.put(propertyId, updatedProperty);
            return #ok(());
        };
        case (null) {
            return #err("Property not found.");
        };
    }
};

public func editInspectionRecord(propertyId: Nat, record: InspectionRecord, recordId: Nat): async Result<(), Text> {
    switch (properties.get(propertyId)) {
        case(?property) {
            let inspections = property.operational.inspections;
            let inspectionsMap: HashMap.HashMap<Nat, InspectionRecord> = HashMap.fromIter<Nat, InspectionRecord>(inspections.vals(), inspections.size(), Nat.equal, natToHash);
            
            switch (inspectionsMap.get(recordId)) {
                case (null) {
                    return #err("Inspection record not found.");
                };
                case (_) {
                    inspectionsMap.put(recordId, record);
                    let inspectionsArray : [(Nat, InspectionRecord)] = Iter.toArray(inspectionsMap.entries());
                    let updatedOperational : OperationalInfo = { property.operational with inspections = inspectionsArray };
                    let updatedProperty : Property = { property with operational = updatedOperational };
                    properties.put(propertyId, updatedProperty);
                    return #ok(());
                };
            }
        };
        case (null) {
            return #err("Property not found.");
        };
    }
};

public func addMaintenanceRecord(propertyId: Nat, record: MaintenanceRecord): async Result<(), Text> {
    switch (properties.get(propertyId)) {
        case(?property) {
            let newRecord : MaintenanceRecord = {record with id = property.operational.maintenance.size()};
            let maintenance = Array.append(property.operational.maintenance, [(newRecord.id, newRecord)]);
            let updatedOperational : OperationalInfo = { property.operational with maintenance = maintenance };
            let updatedProperty: Property = { property with operational = updatedOperational };
            properties.put(propertyId, updatedProperty);
            return #ok(());
        };
        case (null) {
            return #err("Property not found.");
        };
    }
};

public func editMaintenanceRecord(propertyId: Nat, record: MaintenanceRecord, recordId: Nat): async Result<(), Text> {
    switch (properties.get(propertyId)) {
        case(?property) {
            let maintenance = property.operational.maintenance;
            let maintenanceMap: HashMap.HashMap<Nat, MaintenanceRecord> = HashMap.fromIter<Nat, MaintenanceRecord>(maintenance.vals(), maintenance.size(), Nat.equal, natToHash);
            
            switch (maintenanceMap.get(recordId)) {
                case (null) {
                    return #err("Maintenance record not found.");
                };
                case (_) {
                    maintenanceMap.put(recordId, record);
                    let maintenanceArray: [(Nat, MaintenanceRecord)] = Iter.toArray(maintenanceMap.entries());
                    let updatedOperational : OperationalInfo = { property.operational with maintenance = maintenanceArray };
                    let updatedProperty: Property = { property with operational = updatedOperational };
                    properties.put(propertyId, updatedProperty);
                    return #ok(());
                };
            }
        };
        case (null) {
            return #err("Property not found.");
        };
    }
};

public func addTenant(propertyId: Nat, tenant: Tenant): async Result<(), Text> {
    switch (properties.get(propertyId)) {
        case(?property) {
            let newTenant : Tenant = {tenant with id = property.operational.tenants.size()};
            let tenants = Array.append(property.operational.tenants, [(newTenant.id, newTenant)]);
            let updatedOperational : OperationalInfo = { property.operational with tenants = tenants };
            let updatedProperty: Property = { property with operational = updatedOperational };
            properties.put(propertyId, updatedProperty);
            return #ok(());
        };
        case (null) {
            return #err("Property not found.");
        };
    }
};

public func editTenant(propertyId: Nat, tenant: Tenant, tenantId: Nat): async Result<(), Text> {
    switch (properties.get(propertyId)) {
        case(?property) {
            let tenants = property.operational.tenants;
            let tenantsMap: HashMap.HashMap<Nat, Tenant> = HashMap.fromIter<Nat, Tenant>(tenants.vals(), tenants.size(), Nat.equal, natToHash);
            
            switch (tenantsMap.get(tenantId)) {
                case (null) {
                    return #err("Tenant not found.");
                };
                case (_) {
                    tenantsMap.put(tenantId, tenant);
                    let tenantsArray : [(Nat, Tenant)] = Iter.toArray(tenantsMap.entries());
                    let updatedOperational : OperationalInfo = { property.operational with tenants = tenantsArray };
                    let updatedProperty : Property = { property with operational = updatedOperational };
                    properties.put(propertyId, updatedProperty);
                    return #ok(());
                };
            }
        };
        case (null) {
            return #err("Property not found.");
        };
    }
};













}