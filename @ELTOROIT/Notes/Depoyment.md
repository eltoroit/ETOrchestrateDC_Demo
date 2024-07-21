# Notes

-   When data gets randomized, then Sales Orders can't be more than 30 days ago
-   Data Cloud components get packaged and deployed via a Data Kit in a package, not working for Salesforce streams
-   Disable `State and Country/Territory Picklists` before loading data with ETCopyData
-   Some Data Cloud tabs are missing, but we can reach the pages via URL
    -   Data Spaces: `/lightning/o/DataSpace/list?filterName=__Recent`
    -   Query Editor: `/lightning/o/DataQueryWorkspace/list?filterName=__Recent`
    -   Data Graphs: `/lightning/o/DataGraph/list?filterName=__Recent`
-   Simulator requires specific records in `ETOrchestrateDC__DCO_Master__c` and flows
    -   Those are configured in this scratch org, you can get rid of them if needed.
-   Useful SOQL Queries
    -   Monitoring Data Streams...
        -   `SELECT Id, Name, ImportRunStatus, LastRefreshDate, LastNumberOfRowsAddedCount, TotalNumberOfRowsAdded, ExternalRecordIdentifier, TotalRowsProcessed, LastDataChangeStatusDateTime, LastDataChangeStatusErrorCode, ExternalStreamErrorCode FROM DataStream`
    -   `SELECT Id__c, CustomerId_c__c, Name__c, DateBirth_c__c, AssistantPhone__c, Phone__c, HomePhone__c, MobilePhone__c FROM Contact_Home__dll ORDER BY CustomerId_c__c ASC`
-   Orgs

The batch data transform failed due to a runtime error. Make sure that there aren't any null values in the fields mapped to Contact_Point_Phone_Id\_\_c on output node OUTPUT0. Check the output of join and transform node operations to verify that the operations don't introduce null values for related fields.

# ========================================================================================================================

# ========================================================================================================================

# ========================================================================================================================

# Steps without a Data Kit

1. Create Scratch org
2. Perform manual steps
    - ⌛ Wait for Data Cloud to initialize (Blue button)
    - ⬇️ Configure Data Cloud
    - ⬇️ Configure HTTP Callouts (see below)
3. ⬇️ Test it (See below)

# Configure Data Cloud

1.  Ingest Salesforce standard objects
    -   Use the Sales Cloud Data Bundle
    -   No changes for Account and Lead objects
    -   Contact Object
        -   Include these custom fields
            -   Customer Id | CustomerId_c
            -   Date Of Birth | DateBirth_c
            -   Middle Name | MiddleName_c
            -   Person Name | PersonName_c
        -   Create a new formula fied
            -   Name: `Identification Type`
            -   Formula: `"ETOrchestrateDC"`
        -   Create a new formula fied
            -   Name: `Identification Name`
            -   Formula: `"CustomerID"`
2.  Ingest Salesforce custom objects
    -   Use the "All Objects" option
    -   `DCOrder`
        -   Category: Engagement
        -   Event Time Field: OrderCreatedDate_c
    -   `DCOrderItem`
        -   Category: Other
    -   `DCProduct`
        -   Category: Other
3.  Create DLO
    -   Name: `Phone Numbers Normalized`
    -   Category: `Other`
    -   Create these 5 text fields:
        -   Name: `Contact Point Phone Id` (Primary Key)
        -   Name: `Country`
        -   Name: `Party`
        -   Name: `Phone`
        -   Name: `Type`
    -   Add it to the data space
        -   Navigate to this URL: `/lightning/o/DataSpace/list?filterName=__Recent`
        -   Add `Phone Numbers Normalized` DLO to the data space without any filters
4.  Harmonizate the objects based on the Data Dictionary
    -   No changes for Account and Lead objects
    -   [Data Dictionary](hhttps://docs.google.com/spreadsheets/d/1Mxs-FWU3pwnAEEyeXkv0plfgPSk_hY78NlqXdZn1_Uc/edit?gid=226856693#gid=226856693)
5.  Create relationship between Orders and Individuals
    -   Back to the harmonization screen for `Order__c_Home`
    -   Click on the relations button
    -   Click Edit
    -   Click `+ New Relationship` button
    -   `Sales Order`.`Sold To Customer` | `N:1` | `Individual`.`Individual Id`
6.  Create Data Transform
    -   Name: `Normalize Phone Numbers`
    -   Paste this JSON file `@ELTOROIT/Notes/Normalize Phone Numbers.json`
7.  Create the Identity Resolution Ruleset
    -   Primary DMO: `Individual`
    -   Name: `Create Buckets`
    -   Toggle `Run jobs automatically` off
    -   Fuzzy Name and Normalized Email (Standard configuration)
    -   Fuzzy Name and Normalized Phone (Standard configuration)
    -   Fuzzy Name and Normalized Address (Standard configuration)
    -   Ignore reconciliation rules
8.  Create a calculated insight
    -   Create with SQL
    -   Name: `RFM`
    -   Paste this text file `@ELTOROIT/Notes/RFM_sql.txt`
9.  Create Activation target
    -   Type: Data Cloud
    -   Name: `ETOrchestrateDC`
10. Create Segment
    -   Name: `Top Adult Customers`
    -   Segment on: `Unified Individual`
    -   Type: `Standard Publish`
    -   **OR**
        -   Container: `Birth Date` Is Before `Jan 1, 2000`
        -   Container: `RFMCombined__c` = `1111`
11. Create Activation
    -   Activation Target: `ETOrchestrateDC`
    -   Activation Membership: `Unified Individual`
    -   Select both Contact Points (email, phone)
    -   Add Attributes:
        -   Person Name
        -   Birth Date
        -   RFM Combined
        -   Unified Indv Party Identification
            -   Type
            -   Name
            -   Number
    -   Contact Point Phone
        -   Preferred Name for `Formatted E164 Phone Number`: `Phone`
    -   Unified Indv Party Identification
        -   Sort By: `Unified Party Identification Id`
    -   Name: `Activate Top Adult Customers`
    -   Refresh Type: `Incremental Refresh`
12. Create Data Graph
    -   Go to this URL: `/lightning/o/DataGraph/list?filterName=__Recent`
    -   Name: `ETOrchestrateDC Graph`
    -   Primary Data Model Object: `Unified Individual`
    -   Graph
        -   Unified Individual (4/9)
            -   Fields
                -   Unified Individual Id
                -   Birth Date
                -   Person Name
                -   Salutation
            -   Unified Link Individual (4/8)
                -   Fields
                    -   Individual Id
                    -   Key Qualifier Id
                    -   Unified Individual Id
                    -   Match Keys
                -   Individual (6/12)
                    -   Fields
                        -   Individual Id
                        -   Key Qualifier Individual Id
                        -   Birth Date
                        -   Data Source
                        -   Data Source Object
                        -   Person Name
                    -   Sales Order (9/10)
                        -   Fields
                            -   All except Last Modified Date
                        -   Sales Order Product (12/15)
                            -   Fields
                                -   Key Qualifier Sales Order
                                -   Key Qualifier Sales Order Product
                                -   Sales Order
                                -   Sales Order Product
                                -   Data Source
                                -   Data Source Object
                                -   Discount Amount
                                -   List Price Amount
                                -   Ordered Quantity
                                -   Product
                                -   Total Line Amount
                                -   Unit Price Amount
            -   RFM (4/5)
                -   Fields
                    -   Frequency
                    -   MonetaryAvg
                    -   MonetaryLifetime
                    -   Recency

# Configure HTTP Callouts

This is not part of ETOrchestrateDC for two reasons:

1. I do not know what can be configured in a managed package and what is blocked. You need to make some changes, and it may not be possible if it's locked being a managed package.
2. I do not want to fail security review 😳

## Steps

1. Open Connected App [ETOrchestrateDC]
    - [**Open Page**](/lightning/setup/NavigationMenus/home)
        - Keep this tab open, we'll need to make changes later
    - Copy Key/Secret
    - Update project file `etLogs/_user.json`
2. Open Auth. Provider [ETOrchestrateDC]
    - [**Open Page**](/lightning/setup/AuthProviders/home)
        - Reuse the tab that showed the credentials
    - Click [Edit]
    - Paste Key/Secret
    - Click [Save]
    - Copy Callback URL
3. Back to Connected App [ETOrchestrateDC]
    - Paste Callback URL
    - **Changes can take up to 10 minutes to take effect**
4. Go To Named Credentials [ETOrchestrateDC]
    - [**Open Page**](/lightning/setup/NamedCredential/home)
    - Change URL to `https://***.scratch.my.salesforce.com`
5. Go to External Credentials [ETOrchestrateDC]
    - Authenticate
    - Did you get an error?
        - `error=redirect_uri_mismatch&error_description=redirect_uri%20must%20match%20configuration`
            - Validate the `callback URL` on the connected App named `ETOrchestrateDC`
            - If the URL is correct, then you may need to wait few minutes before authenticating again
            - This has to do with the Connected App [ETOrchestrateDC] callback URL
            - Go back in the browser and try again
        - `error=invalid_client_id&error_description=client%20identifier%20invalid`
            - Validate the `consumer key` and `consumer secret` on the auth. provider named `ETOrchestrateDC`
    - If no errors, you should be redirected to the login page.
        - Use credentials from `etLogs/_user.json`
        - You may need to authenticate twice (????)

# Run the simulator

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

1. Flows may take a bit to be active after they are created (30 minutes).
2. Make a change to a contact record
3. On data Cloud refresh the Contact_Home data stream
4. Wait... 😳

# ========================================================================================================================

# ========================================================================================================================

# ========================================================================================================================

# How to work with a Data Kit

1.  Create Data Kit
    -   Name: `ETOrchestrateDC Demo Data Kit`
    -   Data Stream Bundles
        -   Bundle: `ETOrchestrateDC_DataBundle` (Account, Contact, Lead)
        -   Bundle: `ETOrchestrateDC_Custom` (Order, OrderItems, Product)
    -   Data Lake Objects
    -   Data Transforms
    -   Calculated Insights
2.  Create Package
    -   Name: `ETOrchestrateDC DemoDK Package`
    -   Add Metadata
        -   Data Package Kit Definition: `ETOrchestrateDC Demo Data Kit`
        -   Consider this:
            -   Market Segment Definition: `Top_Adult_Customers`

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

# ========================================================================================================================

# ========================================================================================================================

# ========================================================================================================================
