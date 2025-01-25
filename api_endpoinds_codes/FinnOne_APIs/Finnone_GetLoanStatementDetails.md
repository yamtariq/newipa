# Finnone Get Loan Statement Details API

## Description
Retrieves detailed information for a specific loan statement.

## HTTP Method
GET

## Path
/api/v1/Finnone/GetLoanStatementDetails/{ApplicationID}

## Required Parameters
- **ApplicationID** (string, required): The ID of the application.

## Response Model
```json
{
  "LoanStatementDetails": {
    "ApplicationID": "string",
    "PaymentHistory": [
      {
        "PaymentDate": "string",
        "AmountPaid": 0,
        "RemainingBalance": 0
      }
    ],
    "TotalAmount": 0,
    "DueDate": "string"
  }
}
