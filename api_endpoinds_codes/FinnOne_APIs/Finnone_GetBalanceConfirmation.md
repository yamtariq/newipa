# Finnone Get Balance Confirmation API

## Description
Confirms the balance for a specific account in the Finone system.

## HTTP Method
GET

## Path
/api/v1/Finnone/GetBalanceConfirmation/{AccountID}

## Required Parameters
- **AccountID** (string, required): The ID of the account for which the balance is being confirmed.

## Response Model
```json
{
  "BalanceConfirmation": {
    "AccountID": "string",
    "CurrentBalance": 0,
    "Status": "string"
  }
}
