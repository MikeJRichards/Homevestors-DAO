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


//////////////////
//HELPER FUNCTIONS
//////////////////
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

func updatePropertyField<T>(propertyId: Nat, updateFunc: Property -> Property): async () {
    let property = findPropertyById(propertyId);
    let updatedProperty = updateFunc(property);
    properties.put(propertyId, updatedProperty);
};

func nullOrUpdate<T>(newPropertyPart : ?T, propertyPart: T): T {
    switch (newPropertyPart) {
                    case (null) { return propertyPart };
                    case (?value) { return value };
                };
};


//private var nftsMap: HashMap.HashMap<Account, NFT> = HashMap.HashMap<Account, NFT>(0, accountEqual, accountHash);
//private var nextNFTId: Nat = 0;
private var properties: HashMap.HashMap<Nat, Property> = HashMap.HashMap<Nat, Property>(0, Nat.equal, natToHash);
var nextPropertyId : Nat = 0;

//////////////////
//NORMAL FUNCTIONS
//////////////////

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
        valuationId = 0;
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
        insuranceId = 0;
        notesId = 0;
        insurance = [];
        documents = [];
        notes = [];
    };

    let operational : OperationalInfo = {
        tenantId = 0;
        maintenanceId = 0;
        inspectionsId = 0;
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
): async () {
     await updatePropertyField(propertyId, func (property: Property): Property {               
        return { 
            property with 
            details         =      nullOrUpdate(newDetails, property.details);
            financials      =      nullOrUpdate(newFinancials, property.financials);
            invoices        =      nullOrUpdate(newInvoices, property.invoices);
            collection      =      nullOrUpdate(newCollection, property.collection);
            administrative  =      nullOrUpdate(newAdministrative, property.administrative);
            operational     =      nullOrUpdate(newOperational, property.operational);
            governance      =      nullOrUpdate(newGovernance, property.governance);
        };
    });
};

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

public func getInsurancePolicy(propertyId: Nat, policyId : Nat): async InsurancePolicy {
    let property = findPropertyById(propertyId);
    return findValueByKey(property.administrative.insurance, policyId)

};

public func addInsurancePolicy(propertyId: Nat, newPolicy: InsurancePolicy): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedAdministrative = {
            property.administrative with 
            insurance = addElementToArray(property.administrative.insurance, property.administrative.insuranceId, newPolicy);
            insuranceId = property.administrative.insuranceId + 1;
        };        
        return { property with administrative = updatedAdministrative };
    });
};

public func updateInsuranceById(propertyId: Nat, updatedPolicy: InsurancePolicy, id: Nat): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedAdministrative = {
            property.administrative with 
            insurance = updateElementInArray(property.administrative.insurance, updatedPolicy, id);
        };        
        return { property with administrative = updatedAdministrative };
    });
};

public func removeInsuranceById(propertyId: Nat, id: Nat): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedAdministrative = {
            property.administrative with 
            insurance = removeElementInArray(property.administrative.insurance, id);
        };        
        return { property with administrative = updatedAdministrative };
    });
};

public func getNote(propertyId: Nat, policyId : Nat): async Note {
    let property = findPropertyById(propertyId);
    return findValueByKey(property.administrative.notes, policyId)

};

public func addNote(propertyId: Nat, newNote: Note): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedAdministrative = {
            property.administrative with 
            notes = addElementToArray(property.administrative.notes, property.administrative.notesId, newNote);
            notesId = property.administrative.notesId + 1;
        };        
        return { property with administrative = updatedAdministrative };
    });
};

public func updateNoteById(propertyId: Nat, updatedNote: Note, id: Nat): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedAdministrative = {
            property.administrative with 
            notes = updateElementInArray(property.administrative.notes, updatedNote, id);
        };        
        return { property with administrative = updatedAdministrative };
    });
};

public func removeNoteById(propertyId: Nat, id: Nat): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedAdministrative = {
            property.administrative with 
            notes = removeElementInArray(property.administrative.notes, id);
        };        
        return { property with administrative = updatedAdministrative };
    });
};

public func getInspectionRecord(propertyId: Nat, id : Nat): async InspectionRecord {
    let property = findPropertyById(propertyId);
    return findValueByKey(property.operational.inspections, id)
};

public func getLatestInspectionRecord(propertyId: Nat): async InspectionRecord {
    let property = findPropertyById(propertyId);
    return findValueByKey(property.operational.inspections, property.operational.inspectionsId)
};

public func addInspectionRecord(propertyId: Nat, newInspectionRecord: InspectionRecord): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedOperational : OperationalInfo = {
            property.operational with 
            inspections = addElementToArray(property.operational.inspections, property.operational.inspectionsId, newInspectionRecord);
            inspectionsId = property.operational.inspectionsId + 1;
        };        
        return { property with operational = updatedOperational };
    });
};

public func updateInspectionRecordById(propertyId: Nat, updatedInspectionRecord: InspectionRecord, id: Nat): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedOperational = {
            property.operational with 
            inspections = updateElementInArray(property.operational.inspections, updatedInspectionRecord, id);
        };        
        return { property with operational = updatedOperational };
    });
};

public func removeInspectionRecordById(propertyId: Nat, id: Nat): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedOperational : OperationalInfo = {
            property.operational with 
            operational = removeElementInArray(property.operational.inspections, id);
        };        
        return { property with operational = updatedOperational };
    });
};

public func getMaintenanceRecord(propertyId: Nat, id : Nat): async MaintenanceRecord {
    let property = findPropertyById(propertyId);
    return findValueByKey(property.operational.maintenance, id)
};

public func addMaintenanceRecord(propertyId: Nat, newMaintenance: MaintenanceRecord): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedOperational : OperationalInfo = {
            property.operational with 
            maintenance = addElementToArray(property.operational.maintenance, property.operational.maintenanceId, newMaintenance);
            maintenanceId = property.operational.maintenanceId + 1;
        };        
        return { property with operational = updatedOperational };
    });
};

public func updateMaintenanceRecordById(propertyId: Nat, updatedMaintenanceRecord: MaintenanceRecord, id: Nat): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedOperational : OperationalInfo = {
            property.operational with 
            maintenance = updateElementInArray(property.operational.maintenance, updatedMaintenanceRecord, id);
        };        
        return { property with operational = updatedOperational };
    });
};

public func removeMaintenanceRecordById(propertyId: Nat, id: Nat): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedOperational : OperationalInfo = {
            property.operational with 
            operational = removeElementInArray(property.operational.maintenance, id);
        };        
        return { property with operational = updatedOperational };
    });
};

public func getTenantById(propertyId: Nat, id : Nat): async Tenant {
    let property = findPropertyById(propertyId);
    return findValueByKey(property.operational.tenants, id)
};

public func getCurrentTenants(propertyId: Nat): async Tenant {
    let property = findPropertyById(propertyId);
    return findValueByKey(property.operational.tenants, property.operational.tenantId)
};

public func addTenant(propertyId: Nat, newTenant: Tenant): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedOperational : OperationalInfo = {
            property.operational with 
            tenants = addElementToArray(property.operational.tenants, property.operational.tenantId, newTenant);
            tenantsId = property.operational.tenantId + 1;
        };        
        return { property with operational = updatedOperational };
    });
};

public func updateTenancyById(propertyId: Nat, updatedTenant: Tenant, id: Nat): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedOperational : OperationalInfo = {
            property.operational with 
            tenants = updateElementInArray(property.operational.tenants, updatedTenant, id);
        };        
        return { property with operational = updatedOperational };
    });
};

public func removeTenantsById(propertyId: Nat, id: Nat): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedOperational : OperationalInfo = {
            property.operational with 
            operational = removeElementInArray(property.operational.tenants, id);
        };        
        return { property with operational = updatedOperational };
    });
};

public func getPropertyStatus(propertyId: Nat): async PropertyStatus {
    let property = findPropertyById(propertyId);
    return property.collection.status;
};

public func updatePropertyStatus(propertyId: Nat, newStatus: PropertyStatus): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedCollection : Collection = { property.collection with status = newStatus };        
        return { property with collection = updatedCollection };
    });
}; 

public func getPropertyDetails(propertyId: Nat): async PropertyDetails {
    let property = findPropertyById(propertyId);
    return property.details;
};

public func updatePropertyDescription( propertyId: Nat, newDescription: Text): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedDetails : PropertyDetails = { property.details with description = newDescription };        
        return { property with details = updatedDetails };
    });
};

public func updateAdditionalDetails(propertyId: Nat, newDetails: AdditionalDetails): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedDetails : PropertyDetails = { property.details with additional = newDetails };        
        return { property with details = updatedDetails };
    });
};

public shared ({ caller }) func addValuationAndUpdateCurrentValue(propertyId: Nat, newValue: Nat, valuationMethod: ValuationMethod): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let newValuation: ValuationRecord = {
                id = property.financials.valuationId;
                date = Time.now();
                value = newValue;
                method = valuationMethod;
                appraiser = caller;
        };

        let updatedFinancials : Financials = {
            property.financials with 
            currentValue = newValue;
            pricePerSqFoot = newValue / property.details.physical.squareFootage;
            valuationsId = property.financials.valuationId + 1;
            valuations = addElementToArray(property.financials.valuations, property.financials.valuationId, newValuation);
            yeild = Float.fromInt(Nat.div(Nat.mul(property.financials.monthlyRent, 12), newValue));
        };        
        return {property with financials = updatedFinancials};
    });
};

//need to check that changing the rent doesn't influence other aspects of property other than financials
public func updatePropertyMonthlyRent(propertyId: Nat, updatedRent: Nat): async () {
    await updatePropertyField(propertyId, func (property: Property): Property {        
        let updatedFinancials : Financials = {
            property.financials with
            monthlyRent = updatedRent;
            yield = Float.fromInt(Nat.div(Nat.mul(updatedRent, 12),property.financials.currentValue));
        };
        return { property with financials = updatedFinancials};
    });
};

}