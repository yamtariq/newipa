# Finnone List Loans API

## Description
Lists all loans associated with a specific customer.

## HTTP Method
GET

## Path
/api/v1/Finnone/ListLoans/{CustomerID}

## Required Parameters
- **CustomerID** (string, required): The ID of the customer for whom the loans are being listed.

## Response Model
```json
{
  "Loans": [
    {
      "LoanID": "string",
      "LoanAmount": 0,
      "LoanStatus": "string",
      "StartDate": "string",
      "EndDate": "string"
    }
  ]
}
