# 📌 Updated Registration Workflow - High-Standard Implementation Plan

## 🚨 Important Implementation Notes 🚨
✅ **Centralized Theme & Constants Management (`constants.dart`)**  
- **No hardcoded colors/styles** → Everything is referenced from `constants.dart`.  
- **Dark mode colors** are dynamically handled via `isDarkMode`.  
- **RTL/LTR layout and text localization** are controlled by `isArabic`.  

✅ **Global Variables in Every Page**  
- `isDarkMode` → Controls **light/dark mode appearance**.  
- `isArabic` → Controls **RTL/LTR layout & translations**.  

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
3. Display **user’s first name** beside "Welcome".

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

---

## 📌 Next Steps
This structured plan is now implemented. You can download the `.md` file below. 🚀
