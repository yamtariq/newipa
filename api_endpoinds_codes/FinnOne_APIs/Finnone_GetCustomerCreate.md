# Finnone Get Customer Create API

## Description
Creates a new account in the Finone system based on product type.

## HTTP Method
POST

## Path
/api/v1/Finnone/GetCustomerCreate

## Required Parameters
- **Header** (object, required): Contains metadata for the request.
  - **Type** (string, required): The type of request.
  - **RequestId** (integer, required): The ID of the request.
- **Body** (object, required): Contains the details for creating a customer.
  - **ApplicationId** (string, required): The ID of the application.
  - **CustomerInfo** (array, required): Information about the customer.
    - **Citizenship** (string, required): The citizenship status of the customer.
    - **Constituion** (string, required): The constitution of the customer.
    - **Segment** (string, required): The segment of the customer.
    - **DateOfBirth** (string, required): The date of birth of the customer.
    - **EducationQualification** (string, required): The education qualification of the customer.
    - **FamilyName** (string, required): The family name of the customer.
    - **FinancialAmount** (string, required): The financial amount associated with the customer.
    - **FirstName** (string, required): The first name of the customer.
    - **FirstNameEN** (string, required): The first name in English.
    - **MiddleNameEN** (string, required): The middle name in English.
    - **LastNameEN** (string, required): The last name in English.
    - **FamilyNameEn** (string, required): The family name in English.
    - **CardNameEn** (string, required): The card name in English.
    - **Gender** (string, required): The gender of the customer.
    - **HijriDateOfBirth** (string, required): The Hijri date of birth.
    - **IdExpiryDate** (string, required): The expiry date of the ID.
    - **LastName** (string, required): The last name of the customer.
    - **MaritalStatus** (string, required): The marital status of the customer.
    - **MiddleName** (string, required): The middle name of the customer.
    - **Nationality** (string, required): The nationality of the customer.
    - **NationalId** (string, required): The national ID of the customer.
    - **Relation** (string, required): The relation of the customer.
    - **IsSaudiNational** (string, required): Indicates if the customer is a Saudi national.
    - **Tenure** (string, required): The tenure of the customer.
    - **Title** (string, required): The title of the customer.

## Request Model
```json
{
  "Header": {
    "Type": "string",
    "RequestId": 0
  },
  "Body": {
    "ApplicationId": "string",
    "CustomerInfo": [
      {
        "Citizenship": "string",
        "Constituion": "string",
        "Segment": "string",
        "DateOfBirth": "string",
        "EducationQualification": "string",
        "FamilyName": "string",
        "FinancialAmount": "string",
        "FirstName": "string",
        "FirstNameEN": "string",
        "MiddleNameEN": "string",
        "LastNameEN": "string",
        "FamilyNameEn": "string",
        "CardNameEn": "string",
        "Gender": "string",
        "HijriDateOfBirth": "string",
        "IdExpiryDate": "string",
        "LastName": "string",
        "MaritalStatus": "string",
        "MiddleName": "string",
        "Nationality": "string",
        "NationalId": "string",
        "Relation": "string",
        "IsSaudiNational": "string",
        "Tenure": "string",
        "Title": "string"
      }
    ],
    "AddressInfo": [
      {
        "OfficialAddress": [
          {
            "Extension": "string",
            "ZipCode": "string",
            "Region": "string",
            "PropertyStatus": "string",
            "PhoneTwo": "string",
            "PhoneOne": "string",
            "NationalAddress": "string",
            "MobileTwo": "string",
            "MobileOne": "string",
            "MailingAddress": "string",
            "Country": "string",
            "City": "string",
            "AreaCode": "string",
            "AddressType": "string",
            "ThreeAr": "string",
            "TwoAr": "string",
            "OneAr": "string"
          }
        ],
        "ResidenceAddress": [
          {
            "Extension": "string",
            "ZipCode": "string",
            "Region": "string",
            "PropertyStatus": "string",
            "PhoneTwo": "string",
            "PhoneOne": "string",
            "NationalAddress": "string",
            "MobileTwo": "string",
            "MobileOne": "string",
            "MailingAddress": "string",
            "Country": "string",
            "City": "string",
            "AreaCode": "string",
            "AddressType": "string",
            "ThreeAr": "string",
            "TwoAr": "string",
            "OneAr": "string"
          }
        ]
      }
    ],
    "IncomeDetails": [
      {
        "PaymentMethod": "string",
        "HijriFlag": "string",
        "Head": "string",
        "Frequency": "string",
        "SalaryDate": "string",
        "Amount": "string"
      }
    ],
    "EmployerName": "string",
    "Designation": "string",
    "PresentJobStartYear": "string",
    "PresentJobStartMonth": "string",
    "InstrumentType": "string",
    "InstrumentCity": "string",
    "InstrumentBank": "string",
    "InstrumentBankBranch": "string",
    "InstrumentBankAccountNo": "string",
    "InstrumentDwpdc": "string",
    "RepayFrequency": "string",
    "InstallmentNumbers": "string",
    "InstallmentPlan": "string",
    "InstallmentMode": "string",
    "DuePayment": "string",
    "DisbursalType": "string",
    "DisbursalNumber": "string",
    "DisbursalTo": "string",
    "RateEMIFlag": "string",
    "FinancialEMI": "string",
    "ReqProfitType": "string",
    "EffectiveRate": "string",
    "BusinessIRR": "string",
    "FlatRate": "string",
    "AddOnRate": "string",
    "InstallmentStartDate": "string",
    "FirstEMIDue": "string",
    "FirstEMIDate": "string",
    "FirstEMIDueDateHijri": "string",
    "FirstEMIDateHijri": "string",
    "CapitalProffesion": "string",
    "SimahInfo": {
      "ResponseXML": "string",
      "RequestXML": "string"
    },
    "PolicyInfo": [
      {
        "PolicyResult": "string",
        "PolicyString": "string"
      }
    ],
    "ScoringInfo": [
      {
        "TotalScore": "string",
        "ScoreResult": "string"
      }
    ],
    "ApplicationFinalDecision": [
      {
        "Remarks": "string",
        "ApplicationDecision": "string"
      }
    ],
    "DueDate": "string"
  }
}
```

## Response Model
```json
{
  "CifID": "string"
}
