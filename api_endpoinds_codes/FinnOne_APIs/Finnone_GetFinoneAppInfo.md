# Finnone Get Finone App Info API

## Description
Retrieves application information from the Finone system.

## HTTP Method
GET

## Path
/api/v1/Finnone/GetFinoneAppInfo/{ApplicationID}

## Required Parameters
- **ApplicationID** (string, required): The ID of the application.

## Response Model
```json
{
  "ApplicationInfo": {
    "ApplicationID": "string",
    "Status": "string",
    "CreatedDate": "string",
    "UpdatedDate": "string"
  }
}
