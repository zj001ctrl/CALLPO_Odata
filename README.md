# CALLPO_Odata
Call S/4 Po Odata
# S/4HANA Purchase Approval Extension (RAP PoC)

## Goal
Demonstrate how to extend S/4HANA purchase order with custom approval status using RAP model in BTP ABAP Environment.

## Tech Stack
- SAP BTP ABAP Environment (Steampunk)
- RAP (CDS View, Behavior Definition, Service Binding)
- Fiori Elements (List Report + Object Page)
- Communication Scenario: SAP_COM_0053 (simulated)

## Screenshots
![Fiori App](screenshots/fiori-app.png)
![ADT Project](screenshots/adt-project.png)

## Key Code Snippet
abap
define behavior for ZI_PurchaseApproval 
  field (mandatory) approval_status;
  validation validate_status on save 
