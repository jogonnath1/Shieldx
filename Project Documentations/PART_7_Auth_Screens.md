# ShieldX — Full Project Documentation
## Part 7: Presentation — Authentication Screens

Authentication screens live in `lib/common/presentation/auth/`. They handle the complete user onboarding flow from app launch to dashboard.

---

## 7.1 `SplashScreen`

**File**: `lib/common/presentation/auth/splash_screen.dart`  
**Route**: `/splash`

The first screen the app shows. It displays the ShieldX logo with an animated entrance while `AuthNotifier._init()` runs in the background. GoRouter's `redirect()` will automatically navigate away once the auth state is resolved.

**Behavior**:
- Shows logo + tagline animation
- No user interaction — purely passive
- Automatically redirected by the router once `authState.isLoading` becomes `false`

---

## 7.2 `LoginScreen`

**File**: `lib/common/presentation/auth/login_screen.dart`  
**Route**: `/login`

Email and password login form.

**UI Elements**:
- Email text field (keyboard type: `emailAddress`)
- Password text field (with show/hide toggle)
- "Remember Me" checkbox → saves credentials to `PreferencesService`
- "Forgot password?" link → navigates to `/forgot-password`
- Sign In button
- "Create Account" link → navigates to `/register`

**Validation**:
- Uses `AppValidators.email` and `AppValidators.password`

**Auth Flow**:
```
User taps Sign In
  → AppValidators validate inputs
  → ref.read(authNotifierProvider.notifier).signIn(email, password)
        ├── If blocked → shows 'Account Suspended' dialog
        ├── If success → GoRouter redirect handles navigation
        └── If error → shows error snackbar
```

---

## 7.3 `RegisterScreen`

**File**: `lib/common/presentation/auth/register_screen.dart`  
**Route**: `/register`

Multi-step registration wizard. This is the most complex auth screen, split into logical sections.

**Step Structure**:

| Step | Title | Fields |
|------|-------|--------|
| 1 | Account Credentials | Email, Password, Confirm Password |
| 2 | Contact & Identity | Phone (with OTP), NID |
| 3 | Personal Details | Full Name, Profession, Present Address, Permanent Address |

**Registration Flow**:
```
Step 1:
  → Validate email format
  → checkContactExists(email, phone) — show error if email already taken
  → checkNidExists(nid) — show error if NID already registered
  
Step 2:
  → Phone number entry
  → saveMockOtp(phone, generatedOtp) + display demo OTP dialog
  → User enters 6-digit OTP → verifyMockOtp(phone, otp)
  → If verified → proceed to Step 3
  
Step 3:
  → Fill personal details
  → signUp({email, password, name, phone, nid, ...})
  → Router automatically redirects to /home
  
"Cancel Registration" button:
  → deleteIncompleteRegistration() → clears half-created auth user
```

**Edge Cases Handled**:
- Duplicate email → friendly error on Step 1
- Duplicate NID → friendly error on Step 1
- Wrong OTP → error message on Step 2
- Back button mid-registration → prompts to cancel (deletes incomplete account)

---

## 7.4 `ForgotPasswordScreen`

**File**: `lib/common/presentation/auth/forgot_password_screen.dart`  
**Route**: `/forgot-password`

Two-step password reset flow.

**Step 1 — Request Reset**:
- Email input field
- "Send Reset Code" button → `AuthService.sendPasswordResetOtp(email)`
- Shows success message with instructions

**Step 2 — Verify & Reset**:
- OTP input (6 digits)
- New password + confirm password fields
- "Reset Password" → `AuthService.verifyPasswordResetOtp(email, token)` + `updatePassword(newPassword)`
- On success → navigates to `/login`

---

## 7.5 `BlockedScreen`

**File**: `lib/common/presentation/auth/blocked_screen.dart`  
**Route**: `/blocked`

Shown when a user's account has been blocked by an admin.

**Content**:
- Warning icon
- "Account Suspended" heading
- Explanation message
- "Sign Out" button → clears session and navigates to `/login`
- Support contact info

**Reactive Behavior**: If an admin unblocks the user while this screen is open, `_setupProfileSubscription()` in `AuthNotifier` will receive the Realtime update, update the profile state, and GoRouter's `redirect()` will automatically navigate the user away from `/blocked`.

---

## 7.6 Auth Screen State Patterns

All auth screens follow a consistent pattern:

```dart
// 1. Form key for validation
final _formKey = GlobalKey<FormState>();

// 2. Loading state for button spinner
bool _isLoading = false;

// 3. Password visibility toggle
bool _obscurePassword = true;

// 4. Submit handler
Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isLoading = true);
  try {
    await ref.read(authNotifierProvider.notifier).signIn(...);
  } catch (e) {
    AppSnackbar.error(context, e.toString());
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

---

*Next: [Part 8 — Presentation: User Screens](PART_8_User_Screens.md)*
