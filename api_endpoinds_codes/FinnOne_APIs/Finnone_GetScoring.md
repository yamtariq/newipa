# Finnone Get Scoring API

## Description
Retrieves scoring information for a specific application.

## HTTP Method
GET

## Path
/api/v1/Finnone/GetScoring/{ApplicationID}

## Required Parameters
- **ApplicationID** (string, required): The ID of the application.

## Response Model
```json
{
  "ScoringInfo": {
    "ApplicationID": "string",
    "Score": 0,
    "Remarks": "string"
  }
}
