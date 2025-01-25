# Finnone Get API

## Description
Retrieves data related to the Finnone API.

## HTTP Method
POST

## Path
/api/v1/Finnone/Get

## Required Parameters
- **RequestId** (integer, required): The ID of the request.
- **NationalIDNumber** (string, required): The national ID number of the customer.
- **ReceiptDate** (string, required): The date of the receipt.
- **BranchId** (string, required): The ID of the branch.
- **BranchCode** (string, required): The code of the branch.
- **SourceCode** (string, required): The source code for the request.
- **ProductCode** (string, required): The product code associated with the request.
- **SchemeGroup** (string, required): The group of schemes.
- **SchemeCode** (string, required): The code of the scheme.
- **DsaCode** (string, required): The DSA code.
- **DmeCode** (string, required): The DME code.
- **FinancialPurpose** (string, required): The purpose of the financial request.
- **SysType** (string, required): The type of system.

## Request Model
```json
{
  "RequestId": 0,
  "NationalIDNumber": "string",
  "ReceiptDate": "string",
  "BranchId": "string",
  "BranchCode": "string",
  "SourceCode": "string",
  "ProductCode": "string",
  "SchemeGroup": "string",
  "SchemeCode": "string",
  "DsaCode": "string",
  "DmeCode": "string",
  "FinancialPurpose": "string",
  "SysType": "string"
}


## Response Model
```json
{
  "FinOrderNumber": "string"
}
