# Finnone Get Knock Policy API

## Description
Returns results by applying Nayifat policy based on age, income, and length of service.

## HTTP Method
POST

## Path
/api/v1/Finnone/GetKnockPolicy

## Required Parameters
- **applicationID** (string, required): The ID of the application.
- **age** (integer, required): The age of the applicant.
- **income** (integer, required): The income of the applicant.
- **employerID** (integer, required): The ID of the employer.
- **LengthOfService** (integer, required): The length of service in years.

## Request Model
```json
{
  "applicationID": "string",
  "age": 0,
  "income": 0,
  "employerID": 0,
  "LengthOfService": 0
}
```

## Response Model
```json
{
  "eligible": true
}
