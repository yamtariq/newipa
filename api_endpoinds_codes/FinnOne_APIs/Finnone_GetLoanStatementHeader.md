# Finnone Get Loan Statement Header API

## Description
Retrieves the header information for a loan statement.

## HTTP Method
GET

## Path
/api/v1/Finnone/GetLoanStatementHeader/{ApplicationID}

## Required Parameters
- **ApplicationID** (string, required): The ID of the application.

## Response Model
```json
{
  "LoanStatementHeader": {
    "ApplicationID": "string",
    "CustomerName": "string",
    "TotalAmount": 0,
    "DueDate": "string"
  }
}
