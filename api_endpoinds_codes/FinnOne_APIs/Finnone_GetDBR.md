# Finnone Get DBR API

## Description
Returns remaining Debt Burden Ratio calculations and SIMAH eligibility.

## HTTP Method
POST

## Path
/api/v1/Finnone/GetDBR

## Required Parameters
- **applicationID** (string, required): The ID of the application.
- **cfid** (string, required): The customer financial ID.
- **idNumber** (string, required): The national ID number of the customer.
- **NoOfDep** (string, required): The number of dependents.

## Request Model
```json
{
  "applicationID": "string",
  "cfid": "string",
  "idNumber": "string",
  "NoOfDep": "string"
}

```

## Response Model
```json
{
  "dbr": 0
}
