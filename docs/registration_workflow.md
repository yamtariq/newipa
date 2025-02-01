# 📌 Updated Registration Workflow - High-Standard Implementation Plan

## 🚨 Important Implementation Notes 🚨
✅ **Centralized Theme & Constants Management**  
- No hardcoded colors/styles
- Dark mode colors via `isDarkMode`
- RTL/LTR layout via `isArabic`

## **1️⃣ Initial Registration Screen**
### Required User Input:
1. **National ID/IQAMA**
   - 10 digits, starts with 1 or 2
2. **Phone Number**
   - 9 digits, starts with 5 (+966)
3. **Email Address**
4. **Dates (Hijri/Gregorian tabs)**
   - Date of Birth (DD/MM/YYYY)
   - ID Expiry Date (DD/MM/YYYY)
   - Auto-conversion between calendars
   - Both formats stored locally

## **2️⃣ OTP Verification**
1. Store input data locally
2. Send & verify OTP with loading overlay:
   ```dart
   // Loading overlay with rotating company logo
   if (_isLoading)
     Container(
       color: Colors.black.withOpacity(0.5),
       child: Center(
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             RotationTransition(
               turns: CurvedAnimation(
                 parent: _animationController,
                 curve: Curves.linear,
               ),
               child: Image.asset(
                 themeProvider.isDarkMode
                     ? 'assets/images/nayifat-circle-grey.png'
                     : 'assets/images/nayifatlogocircle-nobg.png',
                 width: 100,
                 height: 100,
               ),
             ),
             const SizedBox(height: 24),
             Text(
               widget.isArabic ? 'جاري المعالجة...' : 'Processing...',
               style: const TextStyle(
                 color: Colors.white,
                 fontSize: 16,
                 fontWeight: FontWeight.w500,
               ),
             ),
           ],
         ),
       ),
     ),
   ```
3. Phone number formatting (Centralized in RegistrationService):
   ```dart
   // Format phone number: Add 966 prefix and remove any existing prefix
   final formattedPhone = mobileNo != null 
       ? '966${mobileNo.replaceAll('+', '').replaceAll('966', '')}'
       : '';
   ```
4. OTP Generation Request (Centralized in Constants):
   ```dart
   // Request format defined in constants.dart
   static Map<String, dynamic> otpGenerateRequestBody(String nationalId, String mobileNo) => {
       "nationalId": nationalId,
       "mobileNo": mobileNo,
       "purpose": "REGISTRATION",
       "userId": 1
   }
   ```
5. OTP Generation Response:
   ```json
   {
       "success": true,
       "errors": [],
       "result": {
           "nationalId": "1064448614",
           "otp": 296460,
           "expiryDate": "2025-02-01 18:04:09",
           "successMsg": "Success",
           "errCode": 0,
           "errMsg": null
       },
       "type": "N"
   }
   ```
6. OTP Verification Request (Centralized in Constants):
   ```dart
   // Request format defined in constants.dart
   static Map<String, dynamic> otpVerifyRequestBody(String nationalId, String otp) => {
       "nationalId": nationalId.trim(),
       "otp": otp.trim(),
       "userId": 1
   }
   ```
7. Endpoints (Centralized in Constants):
   ```dart
   // Defined in constants.dart
   static const String proxyBaseUrl = 'https://icreditdept.com/api/testasp';
   static String get proxyOtpGenerateUrl => '$proxyBaseUrl/test_local_generate_otp.php';
   static String get proxyOtpVerifyUrl => '$proxyBaseUrl/test_local_verify_otp.php';
   ```
8. Headers (Centralized in Constants):
   ```dart
   // Defined in constants.dart
   static Map<String, String> get defaultHeaders => {
       'Content-Type': 'application/json',
       'x-api-key': apiKey
   }
   ```
9. Loading states managed for:
   - Initial OTP generation
   - OTP resend functionality
   - OTP verification
   - Government data fetch
10. Allow resend/retry if needed

## **3️⃣ Identity Validation**
1. Check if ID is already registered:
   ```http
   POST /api/Registration/register
   Headers:
     Content-Type: application/json
   Body:
     {
       "checkOnly": true,
       "nationalId": "1234567890",
       "deviceInfo": {
         "deviceId": "device123",
         "platform": "Android",
         "model": "Pixel 6",
         "manufacturer": "Google"
       }
     }
   ```
2. If not registered, proceed with registration
3. If registered, show appropriate message

## **4️⃣ Yakeen API Integration**
- Call after OTP success
- Send stored data
- Store response locally
- Proceed to password setup

## **4️⃣ Password Setup**
- Use existing process
- On success: keep data
- On failure: clear local data

## **5️⃣ Database Registration**
- Register customer in database
- Show success popup
- Proceed to MPIN/Biometrics

## **6️⃣ MPIN & Biometrics**
- Use existing processes
- Store locally only
- No database storage

## **7️⃣ Storage Guidelines**
### Local Storage:
- User input
- Both calendar dates
- MPIN/Biometrics
### Database:
- Customer profile
- Registration details
- No security data

✅ **Always Consider:**
- RTL/LTR support
- Dark/Light themes
- Proper validation
- Secure storage
- Error handling

---

## **1️⃣ Updated Workflow After OTP Success**
1. **OTP Verification Success** → Proceed to **fetch customer details**.  
2. **Call API**:  
   - **Endpoint**:  
     `POST https://172.22.226.203:663/api/Yakeen/getCitizenInfo/json`
   - **Request Body**:
     ```json
     {
       "DATEOFBIRTHHIJRI": "1398-07-01",
       "IDEXPIRYDATE": "1-1-1",
       "IQAMANUMBER": "1032057505"
     }
     ```
3. **Receive Response** and map it to the **Customers table**.
4. **Store data in Customers Table**.
5. **Proceed with Device Registration, MPIN, and Biometrics Setup**.
6. **Navigate to Main Page**.

---

## **2️⃣ Mapping API Response to Customers Table**
The API response fields will be mapped to the Customers table fields as follows:

| **API Response Field**       | **Mapped Customers Table Field**  | **Notes** |
|-----------------------------|----------------------------------|-----------|
| `englishFirstName`          | `first_name`                     | English First Name |
| `englishLastName`           | `last_name`                      | English Last Name |
| `englishSecondName`         | `middle_name`                    | English Middle Name |
| `englishThirdName`          | `third_name`                     | English Third Name |
| `firstName`                 | `first_name_ar`                  | Arabic First Name |
| `familyName`                | `last_name_ar`                   | Arabic Last Name |
| `fatherName`                | `father_name_ar`                 | Arabic Father Name |
| `grandFatherName`           | `grandfather_name_ar`            | Arabic Grandfather Name |
| `gender`                    | `gender`                         | 1 = Male, 2 = Female |
| `dateOfBirth`               | `date_of_birth_hijri`            | Stored in Hijri |
| `idExpiryDate`              | `id_expiry_date_hijri`           | Stored in Hijri |
| `idIssueDate`               | `id_issue_date_hijri`            | Stored in Hijri |
| `idIssuePlace`              | `id_issue_place`                 | ID Issuing Authority |
| `hifizaNumber`              | `hifiza_number`                  | National File Number |
| `hifizaIssuePlace`          | `hifiza_issue_place`             | Place where the record was issued |
| `occupationCode`            | `occupation_code`                | Job Classification |
| `socialStatusDetailedDesc`  | `marital_status`                 | Marital Status |
| `numberOfVehiclesReg`       | `vehicles_registered`            | Number of Registered Vehicles |
| `totalNumberOfCurrentDependents` | `dependents_count`       | Number of Dependents |

---

## **3️⃣ Updating the Registration API Process**
### **1. Before Customer Data is Retrieved**
- User submits **National ID, Phone, Email, Date of Birth, ID Expiry Date**.
- OTP process is initiated **as before**.
- **OTP Verification happens successfully**.

### **2. Fetching Customer Data**
- After OTP verification, **call the Yakeen API** to get customer details.
- If **successful**, extract relevant fields and map them.
- **If Yakeen API fails**, fallback to user-provided details.

### **3. Saving to Database**
- Save **customer data in Customers table**.
- Save **device information in Customer_Devices table** (as before).

---

## **4️⃣ Device Registration (Disables Previous Devices)**
- **After customer data is saved, register the device**.
- **Disable all previous devices** under the same National ID.
- **Device Registration API:**
  - `POST /api/customers/devices/register`
  - **Payload:**
    ```json
    {
      "national_id": "1032057505",
      "device_id": "xxxxxxxxx",
      "device_os": "android/ios",
      "language": "ar/en",
      "theme": "dark/light"
    }
    ```
✅ Ensures only **one active device per user** for security.

---

## **5️⃣ Proceed with MPIN & Biometrics Setup**
1. If MPIN is **not set**, prompt user to create a **6-digit MPIN**.
2. If **biometrics is enabled**, prioritize **Face ID / Fingerprint login**.
3. Store **MPIN & Biometrics securely** using `flutter_secure_storage`.

---

## **6️⃣ Finalizing Registration & Navigation**
1. Save user session **locally**.
2. Navigate to **Main Page** (`main_page`).
3. Display **user's first name** beside "Welcome".

```dart
Text(
  isArabic ? "مرحباً, $firstName!" : "Welcome, $firstName!",
  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
);
```

---

## ✅ **Summary of Key Enhancements**
🔹 **OTP Verification Success Triggers API Call to Fetch Customer Data**  
🔹 **Customer Data from Yakeen API is Mapped to the Customers Table**  
🔹 **Device Registration Disables Previous Devices**  
🔹 **MPIN & Biometrics for Quick Sign-In**  
🔹 **Global Variables for Dark Mode & Arabic Support**  
🔹 **Centralized Theme & Constants Management (`constants.dart`)**  
🔹 **Seamless Android & iOS Support**  
🔹 **Enhanced Loading States with Rotating Logo**  
🔹 **Proper Phone Number Formatting with 966 Prefix**  
🔹 **Improved Error Handling and User Feedback**  
🔹 **Consistent Loading States Across All API Calls**  

---

## 📌 Next Steps
This structured plan is now implemented. You can download the `.md` file below. 🚀

# Registration Workflow Implementation

## Recent Updates

### OTP Generation and Verification
- Added rotating company logo loading overlay during OTP processes
- Implemented proper loading state management for:
  - Initial OTP generation
  - OTP resend functionality
  - OTP verification
  - Government data fetch
- Fixed phone number formatting to include 966 prefix
- Updated to use proxy endpoints for testing

### Loading Overlay Implementation
```dart
// Loading overlay with rotating company logo
if (_isLoading)
  Container(
    color: Colors.black.withOpacity(0.5),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: CurvedAnimation(
              parent: _animationController,
              curve: Curves.linear,
            ),
            child: Image.asset(
              themeProvider.isDarkMode
                  ? 'assets/images/nayifat-circle-grey.png'
                  : 'assets/images/nayifatlogocircle-nobg.png',
              width: 100,
              height: 100,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.isArabic ? 'جاري المعالجة...' : 'Processing...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  ),
```

### Phone Number Formatting
```dart
// Format phone number: Add 966 prefix and remove any existing prefix
final formattedPhone = mobileNo != null 
    ? '966${mobileNo.replaceAll('+', '').replaceAll('966', '')}'
    : '';
```

### API Endpoints
```
Generate OTP: https://187e-51-252-155-185.ngrok-free.app/api/proxy/forward?url=https://icreditdept.com/api/testasp/test_local_generate_otp.php
Verify OTP: https://187e-51-252-155-185.ngrok-free.app/api/proxy/forward?url=https://icreditdept.com/api/testasp/test_local_verify_otp.php
```

### Request/Response Format
```json
// OTP Generation Request
{
    "nationalId": "1064448614",
    "mobileNo": "966556355537",
    "purpose": "REGISTRATION",
    "userId": 1
}

// OTP Generation Response
{
    "success": true,
    "errors": [],
    "result": {
        "nationalId": "1064448614",
        "otp": 296460,
        "expiryDate": "2025-02-01 18:04:09",
        "successMsg": "Success",
        "errCode": 0,
        "errMsg": null
    },
    "type": "N"
}
```

### Headers
```
Content-Type: application/json
x-api-key: 7ca7427b418bdbd0b3b23d7debf69bf7
```

## Loading State Management
The loading state is managed at various points in the registration process:

1. **Initial OTP Generation**
   - Show loading when starting registration
   - Hide loading before showing OTP dialog

2. **OTP Resend**
   - Show loading when resending OTP
   - Hide loading after resend completes

3. **Government Data Fetch**
   - Show loading before fetching data
   - Hide loading before navigation

4. **Error Handling**
   - Hide loading before showing any error messages
   - Proper cleanup in catch blocks

## Theme Support
- Dark mode support for loading overlay
- Different logo assets for dark/light mode
- RTL/LTR support for Arabic/English
- Consistent styling with app theme
