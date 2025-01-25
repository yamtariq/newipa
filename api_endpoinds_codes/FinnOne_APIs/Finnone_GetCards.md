# Finnone Get Cards API

## Description
Retrieves card information associated with a customer.

## HTTP Method
GET

## Path
/api/v1/Finnone/GetCards/{CustomerID}

## Required Parameters
- **CustomerID** (string, required): The ID of the customer for whom the card information is being retrieved.

## Response Model
```json
{
  "Cards": [
    {
      "CardID": "string",
      "CardType": "string",
      "ExpiryDate": "string",
      "Status": "string"
    }
  ]
}
