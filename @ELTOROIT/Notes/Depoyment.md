# Steps

1. Deployed simple metatada
2. Assigned permisison set `psDataCloudData`
3. Disabled `State and Country/Territory Picklists`
4. Loaded data using ETCopyData
5. Configure Data Cloud
    1. Install Sales Cloud Data Bundle
    2. Update permission set `Data Cloud Salesforce Connector`
        - FLS/CRUD for Account, Contact and the custom objects
    3. Ingest using Sales Cloud Data Bundle
        - Contact custom fields needed
            - BirthDate_c
            - FullName_c => PersonName
            - IndividualId_c
            - MiddleName_c
            - TaxRatePercent_c
            - WebSiteURL_c
    4. Ingest custom objects
        - `Order__c`
            - Engagement (CreatedDate) // No spaces!
        - `OrderItem__c`
            - Other
        - `Product__c`
            - Other
    5. Harmonize
        1. Custom Fields in Contact DLO
            1. Contact.IndividualId => PartyIdentification
            2. Contact.TaxRatePercent => New field on individual
        2. Custom Objects
            - Data Dictionary:
                - https://docs.google.com/spreadsheets/d/1_2z5SW-pPwwLkReuPgnGDjRIeI3JGrLTSY16-Xoyo_o/edit?gid=417928767#gid=417928767
        3. Data Transform
            - BUILD THIS!
6. X
