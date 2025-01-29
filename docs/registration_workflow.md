# 📌 Registration Workflow - High-Standard Implementation Plan (after we already setup the asp.net and mssql servers)

## 🚨 Important Implementation Note 🚨
✅ **Centralized Theme & Constants Management**  
- **All theme-related settings and constant data** (such as colors, fonts, paddings, margins, etc.) are **centralized** in the `constants.dart` file.  
- **No colors or styles** should be hardcoded directly in any page.  
- **Dark mode colors** are also handled dynamically based on `isDarkMode`.  
- **RTL/LTR text directions and localized strings** are controlled by `isArabic`.  

---

## 1️⃣ User Input & Validation
- **Fields Required**:
  - National ID (10 digits, starts with **1 or 2**)
  - Phone Number
  - Email Address
  - Date of Birth
  - ID Expiry Date

- **Validations**:
  - **National ID**: Must be **exactly 10 digits**, first digit must be **1 (Saudis) or 2 (Residents)**.
  - **Phone Number**: Must be in a valid Saudi format (`05xxxxxxxx`).
  - **Email**: Proper email format (`example@domain.com`).
  - **Date of Birth & ID Expiry**: If entered in **Gregorian**, convert to **Hijri** before sending to the database.

- **Conversion**:
  - Use `ummalqura_calendar` to handle **Gregorian → Hijri** conversion.
  - Ensure the UI adapts based on `isArabic`:
    - If `isArabic = true`, show **Hijri first**.
    - If `isArabic = false`, show **Gregorian first**.

- **Dark Mode & Language Support**:
  - Use `isDarkMode` for **UI adjustments** (background, text colors).
  - Use `isArabic` for **RTL layout adjustments**.

---

## 2️⃣ OTP Generation & Verification
- **Process**:
  1. When the user submits the registration form, the OTP request is sent via:  
     `POST https://172.22.226.203:6445/api/otp/GetOtpt`
  2. The OTP input should be on a **separate page** (not a popup).
  3. User enters OTP, and the verification request is sent via:  
     `POST https://172.22.226.203:6445/api/otp/GetVerifyOtp`
  4. If successful, proceed to **customer and device registration**.

- **Enhancements**:
  - **OTP UI based on `isDarkMode`**:
    - Dark mode: **Higher contrast colors for visibility**.
    - Light mode: **Standard UI with accessible colors**.
  - **RTL Support (`isArabic`)**:
    - OTP input should be **right-aligned** if `isArabic = true`.
  - **Notifications**:
    - Error messages should be **language-aware (`isArabic`)**.
    - Dark mode should have **contrast-aware text**.

---

## 3️⃣ Customer & Device Registration
- **After OTP Success**:
  - The customer’s data is **recorded in the Customers table** via API.
  - The device information is stored in **both**:
    - `Customers` table (User Profile)
    - `Customer_Devices` table (Device ID, OS type, etc.)

- **Endpoints**:
  - `POST /api/customers/register` (Registers the customer)
  - `POST /api/customers/devices/register` (Registers the device)

- **Data Sent**:
  ```json
  {
    "national_id": "1XXXXXXXXX",
    "phone": "+9665XXXXXXXX",
    "email": "user@example.com",
    "dob_hijri": "1445-08-01",
    "id_expiry_hijri": "1447-12-30",
    "device_id": "xxxxxxxxx",
    "device_os": "android/ios",
    "registration_date": "1445-08-01",
    "language": "ar/en",
    "theme": "dark/light"
  }
  ```
  - Include **language (`ar/en`)** based on `isArabic`.
  - Include **theme (`dark/light`)** based on `isDarkMode`.

---

## 4️⃣ MPIN & Biometrics Setup
- **MPIN (Mandatory)**
  - The user must set a **6-digit MPIN**.
  - Must **confirm MPIN** (re-enter for accuracy).
  - Use **secure storage** to store MPIN locally.

- **Biometrics (Optional)**
  - Use **Face ID / Fingerprint** for authentication.
  - Store **biometric preferences** securely.

- **Dark Mode & Arabic Support**:
  - MPIN entry should adjust for **RTL layout** (`isArabic`).
  - Text contrast should change in **dark mode** (`isDarkMode`).

---

## 5️⃣ Finalizing Registration & Local Storage
- After **successful** MPIN & biometric setup:
  - Navigate user to **Main Page**.
  - Store user’s basic data **locally** for session persistence:
    - `SharedPreferences` or **Flutter Secure Storage**.
  - Display **user’s first name** beside "Welcome" text on **Main Page**.

- **Example:**
  ```dart
  String firstName = userData["name"].split(" ")[0];
  Text(
    isArabic ? "مرحباً, $firstName!" : "Welcome, $firstName!",
    style: TextStyle(
      color: isDarkMode ? Colors.white : Colors.black,
    ),
  );
  ```

---

## 6️⃣ Cross-Platform Compatibility (Android & iOS)
- Ensure all **services, functions, and UI elements** work seamlessly on both **Android** & **iOS**.
- Use **platform-specific APIs** where necessary:
  - **Biometrics**: `local_auth` package.
  - **Secure Storage**: `flutter_secure_storage` package.
  - **Date Conversions**: `ummalqura_calendar`.
- **Ensure `isDarkMode` and `isArabic` apply globally** across the app.

---

## ✅ Summary of Key Enhancements
- **Hijri Date Support**
- **Structured Validations**
- **Improved OTP UI & Notifications**
- **Device Registration**
- **MPIN & Biometrics**
- **Smooth Navigation**
- **Cross-Platform Readiness**
- **Global Variables: `isDarkMode` & `isArabic`**
- **Centralized Theme & Constants Management (`constants.dart`)**

---

## 📌 Next Steps
Let me know if this structured plan is good, then share the **Sign-In Workflow** so I can refine that as well! 🚀
