# Finnone Update Amount API

## Description
Updates the loan amount for a specific application in the Finone system.

## HTTP Method
POST

## Path
/api/v1/Finnone/UpdateAmount

## Required Parameters
- **ApplicationID** (string, required): The ID of the application.
- **NewAmount** (number, required): The new loan amount to be updated.

## Request Model
```json
{
  "ApplicationID": "string",
  "NewAmount": 0
}
```

## Response Model
```json
{
  "Success": true,
  "Message": "Amount updated successfully."
}
