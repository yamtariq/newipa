# Finnone Get Transactions API

## Description
Retrieves transaction records associated with a specific card.

## HTTP Method
GET

## Path
/api/v1/Finnone/GetTransactions/{CardID}

## Required Parameters
- **CardID** (string, required): The ID of the card for which transactions are being retrieved.

## Response Model
```json
{
  "Transactions": [
    {
      "TransactionID": "string",
      "Amount": 0,
      "Date": "string",
      "Description": "string"
    }
  ]
}
