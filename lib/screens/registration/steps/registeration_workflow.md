Here's a detailed breakdown of what we've implemented and the overall plan:

Implemented So Far:
UI Layout:
- Half-circle logo in top-right corner (transparent)
- Registration title in the middle
- Progress indicator with 5 steps
- Form fields below
- Cancel/Next buttons at bottom

Progress Steps:
- Basic Info (current)
- OTP
- Password
- MPIN
- Biometric

Each step shows number and label
Current step highlighted

Form Fields:
- National ID/IQAMA:
  * Must be 10 digits
  * Must start with 1 or 2
  * Required field
  * Proper validation messages
  * Check if ID exists
  * If ID exists, show dialog with login option (TODO: Implement login screen navigation)

- Mobile Number:
  * Fixed +966 prefix
  * 9 digits required
  * Must start with 5
  * Proper validation messages

- Date of Birth:
  * Calendar picker with Gregorian/Hijri option
  * Must be 18+ years old
  * Custom Hijri calendar implementation
  * Proper date format display

- Email:
  * Required field
  * Email format validation
  * Proper validation messages

Localization:
- Full Arabic/English support
- RTL/LTR handling
- Bilingual labels and messages
- Proper text alignment

Agreed Final Plan:
API Integration:
- Check if user exists ✓
- If exists: offer login option ✓
- If new: proceed with registration

TODO Next Steps:
1. Create RegistrationData model
2. Implement OTP Verification screen
3. Create Login screen and navigation (for existing users)
4. Password Setup:
   - Password creation with rules
   - Password confirmation
   - Password strength indicator
5. MPIN Setup:
   - 6-digit numeric PIN
   - PIN confirmation
   - Failed attempts handling
6. Biometric Registration:
   - Fingerprint registration
   - Face ID registration
   - Fallback to MPIN option
7. Final Steps:
   - Government API integration
   - Pull user details
   - Session management
   - Main page navigation