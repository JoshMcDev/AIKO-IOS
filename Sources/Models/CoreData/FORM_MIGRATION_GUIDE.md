# Government Forms Core Data Migration Guide

## Overview
This guide documents the migration process for adding Government Forms support to the AIKO Core Data model.

## Migration Steps

### 1. Update Core Data Model

The following changes need to be made to the Core Data model:

#### New Entity: GovernmentFormData
```xml
<entity name="GovernmentFormData" representedClassName="GovernmentFormData" syncable="YES">
    <attribute name="createdDate" attributeType="Date" usesScalarValueType="NO"/>
    <attribute name="formData" attributeType="Binary"/>
    <attribute name="formNumber" attributeType="String"/>
    <attribute name="formType" attributeType="String"/>
    <attribute name="id" attributeType="UUID" usesScalarValueType="NO"/>
    <attribute name="lastModifiedDate" attributeType="Date" usesScalarValueType="NO"/>
    <attribute name="metadata" optional="YES" attributeType="Binary"/>
    <attribute name="revision" optional="YES" attributeType="String"/>
    <attribute name="status" attributeType="String" defaultValueString="draft"/>
    <relationship name="acquisition" optional="YES" maxCount="1" deletionRule="Nullify" destinationEntity="Acquisition" inverseName="forms" inverseEntity="Acquisition"/>
</entity>
```

#### Update Acquisition Entity
Add new relationship to Acquisition:
```xml
<relationship name="forms" optional="YES" toMany="YES" deletionRule="Cascade" destinationEntity="GovernmentFormData" inverseName="acquisition" inverseEntity="GovernmentFormData"/>
```

### 2. Create Core Data Classes

Two files have been created:
- `GovernmentFormData+CoreDataClass.swift` - Contains the class implementation and convenience methods
- `GovernmentFormData+CoreDataProperties.swift` - Contains the Core Data properties and fetch requests

### 3. Update Xcode Model

1. Open the `.xcdatamodeld` file in Xcode
2. Add the new `GovernmentFormData` entity with all attributes
3. Add the `forms` relationship to the `Acquisition` entity
4. Set the inverse relationships properly
5. Generate NSManagedObject subclasses if using manual generation

### 4. Create Migration Mapping

If you have existing data, create a migration mapping:

1. Create a new model version in Xcode
2. Set the new version as the current model
3. Create a mapping model if needed for complex migrations

### 5. Test Migration

```swift
// Test the migration with existing data
let container = NSPersistentContainer(name: "AIKO")

// Enable migration options
let description = container.persistentStoreDescriptions.first
description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

container.loadPersistentStores { _, error in
    if let error = error {
        fatalError("Failed to load store: \(error)")
    }
}
```

## Usage Examples

### Creating a Form

```swift
let formService = GovernmentFormService(context: viewContext)

// Create form data
let metadata = FormMetadata(
    createdBy: "John Doe",
    agency: "GSA",
    purpose: "Commercial acquisition"
)

let formData = FormData(
    formNumber: "SF1449",
    revision: "REV FEB 2020",
    fields: [:],
    metadata: metadata
)

// Create and save form
let savedForm = try await formService.createForm(
    type: GovernmentFormData.FormType.sf1449,
    formData: formData,
    for: acquisitionId
)
```

### Retrieving Forms

```swift
// Get all forms for an acquisition
let forms = try await formService.getForms(for: acquisitionId)

// Get specific form type
let sf1449Forms = try await formService.getForms(ofType: GovernmentFormData.FormType.sf1449)

// Convert to domain model
if let formEntity = forms.first {
    let sf1449 = try formService.convertToForm(formEntity, type: SF1449Form.self)
}
```

### Updating Form Status

```swift
try await formService.updateFormStatus(
    id: formId,
    status: GovernmentFormData.Status.approved
)
```

## Form Types Supported

- **SF 1449**: Solicitation/Contract/Order for Commercial Products
- **SF 33**: Solicitation, Offer and Award
- **SF 30**: Amendment of Solicitation/Modification of Contract
- **SF 18**: Request for Quotations
- **SF 26**: Award/Contract
- **SF 44**: Purchase Order - Invoice - Voucher
- **DD 1155**: Order for Supplies or Services

## Data Structure

Forms are stored as JSON-encoded binary data in the `formData` attribute. This allows:
- Flexibility in form structure
- Easy serialization/deserialization
- Version compatibility
- Efficient storage

## Integration Points

1. **AcquisitionService**: Add methods to work with forms
2. **UI Layer**: Create form selection and editing views
3. **Export**: Add form export capabilities
4. **Validation**: Integrate form validation rules
5. **Workflow**: Add form approval workflows

## Performance Considerations

- Forms are loaded lazily through relationships
- Binary data is only decoded when needed
- Use batch fetching for multiple forms
- Consider pagination for large form lists

## Security Considerations

- Form data may contain sensitive information
- Ensure proper access controls
- Audit form access and modifications
- Consider encryption for sensitive fields

## Future Enhancements

1. **Form Versioning**: Track form changes over time
2. **Form Templates**: Pre-filled forms based on common scenarios
3. **Form Workflows**: Automated approval chains
4. **Form Analytics**: Track form usage and completion rates
5. **Form Integration**: Connect with external systems