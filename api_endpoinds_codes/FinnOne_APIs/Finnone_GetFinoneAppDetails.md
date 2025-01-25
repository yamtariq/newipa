# Finnone Get Finone App Details API

## Description
Retrieves detailed information about a specific application in the Finone system.

## HTTP Method
GET

## Path
/api/v1/Finnone/GetFinoneAppDetails/{ApplicationID}

## Required Parameters
- **ApplicationID** (string, required): The ID of the application.

## Response Model
```json
{
  "ApplicationDetails": {
    "ApplicationID": "string",
    "CustomerName": "string",
    "LoanAmount": 0,
    "Status": "string",
    "CreatedDate": "string",
    "UpdatedDate": "string"
  }
}
