# Finnone Get Finone Customer Info API

## Description
Returns customer identification ID number from the Finone system by National ID number.

## HTTP Method
GET

## Path
/api/v1/Finnone/GetFinoneCustomerInfo/{IDNumber}

## Required Parameters
- **IDNumber** (string, required): The national ID number of the customer.

## Response Model
```json
{
  "CustomerInfo": {
    "IDNumber": "string",
    "Name": "string",
    "DateOfBirth": "string",
    "Nationality": "string",
    "AccountStatus": "string"
  }
}
