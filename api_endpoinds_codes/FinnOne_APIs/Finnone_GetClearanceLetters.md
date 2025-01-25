# Finnone Get Clearance Letters API

## Description
Returns clearance letter data to fill the clearance letter template by customer contract number.

## HTTP Method
GET

## Path
/api/v1/Finnone/GetClearanceLetters/{id}

## Required Parameters
- **id** (string, required): The ID of the customer contract.

## Response Model
```json
{
  "CustomerName": "string",
  "ContractNumber": "string",
  "EMI": 0,
  "NationalId": "string",
  "AccountNumber": "string",
  "AccountStatus": "string",
  "ROWID": 0
}
