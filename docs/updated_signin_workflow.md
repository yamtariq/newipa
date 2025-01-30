# 📌 Sign-In Workflow - High-Standard Implementation Plan

## 🚨 Important Implementation Notes 🚨
✅ **Centralized Theme & Constants Management (`constants.dart`)**  
- **No hardcoded colors/styles** → Everything is referenced from `constants.dart`.  
- **Dark mode colors** are dynamically handled via `isDarkMode`.  
- **RTL/LTR layout and text localization** are controlled by `isArabic`.  

✅ **Global Variables in Every Page**  
- `isDarkMode` → Controls **light/dark mode appearance**.  
- `isArabic` → Controls **RTL/LTR layout & translations**.  

---

## **1️⃣ Two Paths for Sign-In**
### **🔹 Quick Sign-In (Biometrics First, Then MPIN)**
🔹 **Priority Order:**  
1️⃣ **Biometrics (Face ID/Fingerprint) → Preferred & Default**  
   - If **biometrics is enabled & set up**, it will be the **first authentication method**.  
   - The user **will not see the MPIN screen** unless biometrics fails or is not set up.  

2️⃣ **MPIN (Fallback if Biometrics is Unavailable)**  
   - If biometrics **is not set up or fails**, show the **MPIN entry screen**.  
   - User enters a **6-digit MPIN** to authenticate.  
   - If MPIN fails, show an **error message** and allow retries.  

✅ **On Successful Authentication:** Navigate to **Main Page (`main_page`)**.  
❌ **On Failure:** Prompt for retry or fallback to **Main Sign-In**.  

---

### **🔹 Main Sign-In (Username & Password)**
1️⃣ **User enters their username & password.**  
2️⃣ **Validate password before sending to API.**  
3️⃣ **Send request to authentication API:**  
   `POST /api/auth/login`  
   ```json
   {
     "username": "user@example.com",
     "password": "securePassword123",
     "device_id": "xxxxxxxxx"
   }
   ```
4️⃣ **On successful login:**  
   - Proceed to **OTP verification** (same process as Registration).  
   - If OTP **fails**, ask for retry.  

5️⃣ **On successful OTP verification:**  
   - **Perform Device Registration (This disables all previous devices for this user)**.  
   - Setup **MPIN & Biometrics** if not already done.  
   - Navigate to **Main Page (`main_page`)**.  

---

## **2️⃣ OTP Verification**
🔹 **Same process as Registration:**  
- OTP **generation request**:  
  `POST https://172.22.226.203:6445/api/otp/GetOtpt`  
- OTP **verification request**:  
  `POST https://172.22.226.203:6445/api/otp/GetVerifyOtp`  
- **Better UI/UX**:  
  - OTP input is on a **separate page** (not a popup).  
  - Clear error messages & countdown timer.  
  - Right-aligned input if `isArabic = true`.  

---

## **3️⃣ Device Registration (Disables Previous Devices)**
- **After OTP success, the new device replaces all other registered devices.**  
- **Endpoint for Device Registration:**  
  - `POST /api/customers/devices/register`  
  - This **disables all previous devices under the same National ID** and registers the new one.  
- **Data Sent:**
  ```json
  {
    "national_id": "1XXXXXXXXX",
    "device_id": "xxxxxxxxx",
    "device_os": "android/ios",
    "language": "ar/en",
    "theme": "dark/light"
  }
  ```
✅ **Ensures only one active device per user** for security.  

---

## **4️⃣ MPIN & Biometrics Setup**
- **MPIN (Mandatory)**:
  - If not set, prompt user to create a **6-digit MPIN**.
  - Store securely using **Flutter Secure Storage**.  
- **Biometrics (Optional, but Preferred for Quick Sign-In)**:
  - Allow **Face ID / Fingerprint** setup.
  - Save preference securely.  
  - **Biometrics will be prioritized over MPIN in future logins**.  

---

## **5️⃣ Finalizing Sign-In & Navigation**
- After a successful sign-in:
  - Store user’s details **locally** (`SharedPreferences`).  
  - Navigate to **Main Page (`main_page`)**.  
  - Show user’s **first name** beside “Welcome”.  

```dart
Text(
  isArabic ? "مرحباً, $firstName!" : "Welcome, $firstName!",
  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
);
```

---

## **6️⃣ Cross-Platform Compatibility (Android & iOS)**
✅ **Ensure all UI elements work seamlessly on both platforms.**  
✅ **Use platform-specific APIs where necessary:**  
  - **Biometrics:** `local_auth` package.  
  - **Secure Storage:** `flutter_secure_storage` package.  
  - **Date Conversions:** `ummalqura_calendar`.  

---

## ✅ **Summary of Key Enhancements**
🔹 **Two Sign-In Paths (Quick + Main Sign-In)**  
🔹 **Quick Sign-In Prioritizes Biometrics Over MPIN**  
🔹 **Secure OTP Verification (Same as Registration)**  
🔹 **New Device Registration Disables All Previous Devices**  
🔹 **MPIN & Biometrics for Quick Access**  
🔹 **Global Variables for Dark Mode & Arabic Support**  
🔹 **Centralized Theme & Constants Management (`constants.dart`)**  
🔹 **Seamless Android & iOS Support**  

---

## 📌 Next Steps
This structured plan is now implemented. You can download the `.md` file below. 🚀
