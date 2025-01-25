# Finnone Get Loans API

## Description
Returns customer loans records by National ID number.

## HTTP Method
GET

## Path
/api/v1/Finnone/GetLoans/{id}

## Required Parameters
- **id** (string, required): The ID of the customer for whom the loans are being retrieved.

## Response Model
```json
{
  "LoanRecords": [
    {
      "LoanID": "string",
      "LoanAmount": 0,
      "LoanStatus": "string",
      "StartDate": "string",
      "EndDate": "string"
    }
  ]
}
