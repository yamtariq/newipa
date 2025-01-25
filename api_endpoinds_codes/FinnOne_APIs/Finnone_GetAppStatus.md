# Finnone Get App Status API

## Description
Retrieves the status of a specific application in the Finone system.

## HTTP Method
GET

## Path
/api/v1/Finnone/GetAppStatus/{ApplicationID}

## Required Parameters
- **ApplicationID** (string, required): The ID of the application.

## Response Model
```json
{
  "ApplicationStatus": {
    "ApplicationID": "string",
    "Status": "string",
    "Remarks": "string"
  }
}
