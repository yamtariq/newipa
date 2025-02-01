# OTP Verification Endpoint

## Method
**POST**

## URL
```
<!-- https://172.22.226.203:6445/api/otp/GetVerifyOtp --> change to this in production

https://icreditdept.com/api/testasp/test_local_verify_otp.php

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
  "otp": "620563",
  "userId": "1"
}
```

## Request Parameters
| Parameter  | Type   | Mandatory | Description |
|------------|--------|-----------|-------------|
| nationalId | number | Yes       | 10-digit national ID (e.g., 1000000123, 2111112223) |
| otp        | string | Yes       | 6-digit OTP (e.g., "456123", "024563") |
| userId     | string | Yes       | Send `"1"` indicating the request source |

## Sample Response (Success)
```json
{
    "success": true,
    "errors": [],
    "result": {
        "nationalId": "1081643650",
        "otp": "620563",
        "verifiedFlag": true,
        "successMsg": "Verified successfully.",
        "errCode": 0,
        "errMsg": null
    },
    "type": "N",
    "message": null,
    "code": null
}
```
