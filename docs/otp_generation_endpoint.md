# OTP Generation Endpoint

## Method
**POST**

## URL
```
https://172.22.226.203:6445/api/otp/GetOtpt
```

## Headers
| Header Name       | Type   | Mandatory | Description |
|------------------|--------|-----------|-------------|
| Authorization    | string | Yes       | Base64 encoded username and password (e.g., `Basic TmF5aWZhdDpOYXlpZmF0RkM=`) |
| X-APP-ID        | string | Yes       | API access App ID |
| X-API-KEY       | string | Yes       | API access key |
| X-Organization-No | string | Yes     | Organization number |

## Request Body (JSON)
```json
{
  "nationalId": "1081643650",
  "mobileNo": "966569801861",
  "purpose": "Login",
  "userId": "1"
}
```

## Request Parameters
| Parameter  | Type   | Mandatory | Description |
|------------|--------|-----------|-------------|
| nationalId | number | Yes       | 10-digit national ID (e.g., 1000000123, 2111112223) |
| mobileNo   | string | Yes       | 12-digit mobile number (e.g., 966596065248) |
| purpose    | string | Yes       | Purpose for OTP (e.g., "Login", "Acceptance", "Verification") |
| userId     | string | Yes       | Send `"1"` indicating the request source |

## Sample Response (Success)
```json
{
    "success": true,
    "errors": [],
    "result": {
        "nationalId": "1081643650",
        "otp": "620563",
        "expiryDate": "2023-03-19T12:20:59.4541355+03:00",
        "successMsg": "Success",
        "errCode": 0,
        "errMsg": null
    },
    "type": "N",
    "message": null,
    "code": null
}
```
