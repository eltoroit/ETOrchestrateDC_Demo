# Notes

-   When data gets randomized, then Sales Orders can't be more than 30 days ago
-   Data Cloud components get packaged and deployed via a Data Kit in a package, not working for Salesforce streams
-   Disable `State and Country/Territory Picklists`

# Steps without a Data Kit

1. Create Scratch org
2. Perform manual steps
    - ⌛ Wait for Data Cloud to initialize (Blue button)
    - ⬇️ Configure Data Cloud
    - ⬇️ Configure HTTP Callouts (see below)
3. ⬇️ Test it (See below)

# Configure Data Cloud

1. Ingest Salesforce data via the Sales Cloud Data Bundle

    - Only need to make changes to the Contact Object
    -

2. Ingest using Sales Cloud Data Bundle
    - Contact custom fields needed
        - Customer Id | CustomerId_c
        - Date Of Birth | DateBirth_c
        - Middle Name | MiddleName_c
        - Person Name | PersonName_c
        - Create `Identification Name` "CustomerID" (both both type and name to this)
    - Use defaults for Accounts and Leads
3. Ingest custom objects
    - `DCOrder`
        - Engagement (OrderCreatedDate_c)
    - `DCOrderItem`
        - Other
    - `DCProduct`
        - Other
4. Create DLO
    - `Normalize Phone Numbers`
    - Add it to the data space
5. Harmonize
6. Custom Fields in Contact DLO
    1. Contact.CustomerId => PartyIdentification
7. Custom Objects
    - [Data Dictionary](hhttps://docs.google.com/spreadsheets/d/1Mxs-FWU3pwnAEEyeXkv0plfgPSk_hY78NlqXdZn1_Uc/edit?gid=226856693#gid=226856693)
8. Data Transform

-   Name: `Normalize Phone Numbers`

5. Identity Resolution

-   Name: `Create Buckets`
-   Toggle `Run jobs automatically` off
-   Fuzzy Name and Normalized Email (Standard configuration)
-   Fuzzy Name and Normalized Phone (Standard configuration)
-   Fuzzy Name and Normalized Address (Standard configuration)
-   Ignore reconciliation rules

6. Calculated Insights
   Name: `RFM`
1. Create Activation target

-   Type: Data Cloud
-   Name: `ETOrchestrateDC`

2. Create Segment

-   Name: `Top Adult Customers`
-   **OR**
    -   Container: `Birth Date` Is Before `Jan 1, 2000`
    -   Container: `RFMCombined__c` = `1111`

3. Create Activation

-   Name: `Activate Top Adult Customers`
-   Fields:
    -   Person Name
    -   Birth Date
    -   RFM Combined
    -   Unified Party
        -   Party
        -   Type
        -   Name
        -   Number

4.  Data Graph
    Name: `ETOrchestrateDC Graph`

// ???

1.  Create Data Kit
    -   Name: `ETOrchestrateDC Demo Data Kit`
    -   Data Stream Bundles
        -   Bundle: `ETOrchestrateDC_DataBundle` (Account, Contact, Lead)
        -   Bundle: `ETOrchestrateDC_Custom` (Order, OrderItems, Product)
    -   Data Lake Objects
    -   Data Transforms
    -   Calculated Insights
1.  Create Package
    -   Name: `ETOrchestrateDC DemoDK Package`
    -   Add Metadata
        -   Data Package Kit Definition: `ETOrchestrateDC Demo Data Kit`
        -   Consider this:
            -   Market Segment Definition: `Top_Adult_Customers`

========================================================================================================================

# Steps to Install Metadata

# Configure Data Cloud using "ETOrchestrateDC" Data Kit

1.  Create Data Streams
    -   Using Data Kits & Package
    -   Create connector `ETOrchestrateDC`
    -   Accept all defaults
2.  Create DLO from Data Kit
    -   **RENAME IT**
    -   Validate name `Customer Phones`
3.  Create Data Transform from Data Kit
    -   Name `Normalize Phone Numbers`
    -   Don't run it!
4.  Identity Resolution
    -   Name: `ETOrchestrateDC`
    -   Toggle `Run jobs automatically` off
    -   Fuzzy Name and Normalized Email (Standard configuration)
    -   Fuzzy Name and Normalized Phone (Standard configuration)
    -   Fuzzy Name and Normalized Address (Standard configuration)
    -   Custom Rule (`Party Identification => Customer ID`)
    -   Ignore reconciliation rules
5.  Calculated Insights
    -   From Data Kit
6.  Create Activation target
    -   Name: `ETOrchestrateDC`
    -   Type: Data Cloud
7.  Create Segment
    -   Name: `Top Adult Customers`
    -   **OR**
        -   Container: `Birth Date` Is Before `Jan 1, 2000`
        -   Container: `RFMCombined__c` = `1111`
8.  Create Activation
    -   Name: `Activate Top Adult Customers`

# Configure HTTP Callouts

1. Open Connected App [ETOrchestrateDC]
    - **/lightning/setup/NavigationMenus/home**
    - Get Key/Secret
    - Update project file `etLogs/_user.json`
2. Keep this tab open, we'll need to make changes later
3. Open Auth. Provider [ETOrchestrateDC]
    - **/lightning/setup/AuthProviders/home**
    - Click [Edit]
    - Set Key/Secret
    - Copy Callback URL
4. Back to Connected App [ETOrchestrateDC]
    - Paste Callback URL
    - **Changes can take up to 10 minutes to take effect**
5. Enable UN/PW flow
    - **/lightning/setup/OauthOidcSettings/home**
    - Allow OAuth Username-Password Flows
6. Go To Named Credentials [ETOrchestrateDC]
    - **/lightning/setup/NamedCredential/home**
    - Change URL to `https://***.scratch.my.salesforce.com`
7. Go to External Credentials [ETOrchestrateDC]
    - Wait...
        - Wait few minutes before next step
        - We may try it, but if it fails... keep waiting!
        - This has to do with the Connected App [ETOrchestrateDC] callback URL
    - Authenticate

# Test It

1.  Validate Custom metadata types [ETOrchestrateDC]
    -   **/lightning/setup/CustomMetadata/home**
    -   Confirm [DeleteTempRecords] has a value of [false] (original value `true`)
    -   Confirm [DelayMinutes] has a value of [1] (original value `5`)
2.  Monitor Time-Based Workflow
    -   **/lightning/setup/DataManagementManageWorkflowQueue/home**
    -   Search
        -   Object Starts With DCO
3.  Debug by running `Simulator` annonymous Apex

# Ingest Data

1. Flows take a bit to be active.
2. Run Node.js App
3. Validate the correct Org
    - Option `6. Dispay My Domain`
    - Validate against URL in browser
4. Randomize customer data
    - Option `5. Update Customers.json`
5. Ingest Data
    - New org, ingest all Data Streams
    - Options in order:
        - Option `1. Ingest`
        - Option `2. BULK`
        - Option `6. All`
6. Test Again
7. Randomize customer data
    - Option `5. Update Customers.json`
8. Ingest Data
    - No need to ingest all records, only customers
    - Options in order:
        - Option `1. Ingest`
        - Option `2. BULK`
        - Option `1. Customers` (all 500 customers) or `2. Customers (5 records)`

===

# Packages

-   Retrieve package
    1.  `rm -rf packagesFolder && mkdir packagesFolder && cd packagesFolder`
    2.  `sf project retrieve start --target-metadata-dir . --package-name "ETOrchestrateDC DemoDK Package" --target-org prDCO_Demo64276`
    3.  `unzip unpackaged.zip`
-   Deploy the metadata
    1.  `sf project deploy start --dry-run --metadata-dir="ETOrchestrateDC DemoDK Package" --target-org soDCO_TestPKG_DC`
    2.  `sf project deploy start --metadata-dir="ETOrchestrateDC DemoDK Package" --target-org soDCO_TestPKG_DC`
-   Install Package
    -   `sf package install --apex-compile=all --package 04tHu000003j1FP --wait=30 --no-prompt --json --target-org soDCO_TestPKG_DC`
    -   `sf org open --target-org soDCO_TestPKG_DC`

# Deploying Data Cloud
