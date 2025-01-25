# Finnone Prepare Loan Statement Data API

## Description
Prepares loan statement data for a specific application.

## HTTP Method
POST

## Path
/api/v1/Finnone/PrepareLoanStatementData

## Required Parameters
- **ApplicationID** (string, required): The ID of the application.
- **StatementPeriod** (string, required): The period for which the loan statement is prepared.

## Request Model
```json
{
  "ApplicationID": "string",
  "StatementPeriod": "string"
}

```

## Response Model
```json
{
  "LoanStatement": {
    "ApplicationID": "string",
    "TotalAmount": 0,
    "DueDate": "string",
    "PaymentHistory": [
      {
        "PaymentDate": "string",
        "AmountPaid": 0
      }
    ]
  }
}
