# LinkLab Main Frontend PRD Alignment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Align the main LinkLab frontend demo flow with the root PRD by making onboarding, accessibility preferences, profile data, recent help, and featured content behave like a coherent product instead of disconnected static screens.

**Architecture:** Keep the existing Flutter screen structure and demo-first mode, but introduce a lightweight local session layer backed by `SharedPreferences`. Reuse that state in auth/onboarding, home, profile, and fallback service paths so the app works consistently without Supabase.

**Tech Stack:** Flutter, SharedPreferences, existing `freezed` models, existing local storage service, existing home/community/user-center screens.

---

### Task 1: Add a local app session layer for demo mode

**Files:**
- Create: `linklab/lib/services/app_session_service.dart`
- Modify: `linklab/lib/main.dart`
- Modify: `linklab/lib/app.dart`

**Step 1: Initialize a single source of truth for local user session**

Create `AppSessionService` as a singleton `ChangeNotifier` that:
- initializes `LocalStorage`
- loads stored `UserModel` and `AccessibilityPreferences`
- seeds demo help history when storage is empty
- exposes `isLoggedIn`, `isFirstLaunch`, `userProfile`, and `preferences`

**Step 2: Make app bootstrap use the session service**

In `main.dart`, call session initialization before `runApp`.

**Step 3: Make root app react to preferences and login state**

In `app.dart`, use the session service to:
- choose initial screen (`OnboardingScreen`, `LoginScreen`, or `MainScreen`)
- switch between normal/high-contrast theme
- apply stored font scale globally

### Task 2: Persist onboarding and accessibility preferences

**Files:**
- Modify: `linklab/lib/screens/auth/verification_screen.dart`
- Modify: `linklab/lib/screens/auth/identity_select_screen.dart`
- Modify: `linklab/lib/screens/auth/disability_select_screen.dart`
- Modify: `linklab/lib/screens/auth/preference_screen.dart`

**Step 1: Pass onboarding context through the auth flow**

Propagate `phone`, `role`, and `disabilityTypes` through verification → identity → disability → preference.

**Step 2: Save onboarding completion into local session**

When the user finishes `PreferenceScreen`, store:
- phone
- selected role(s)
- disability type(s)
- accessibility preferences
- login state
- first-launch state

**Step 3: Support preference editing after login**

Allow `PreferenceScreen` to open in edit mode from “我的” and update preferences without recreating the profile.

### Task 3: Replace static home/profile placeholders with session-backed data

**Files:**
- Modify: `linklab/lib/screens/home/home_screen.dart`
- Modify: `linklab/lib/screens/home/profile_screen.dart`

**Step 1: Personalize the homepage**

Use stored profile data for greeting and add a compact date/time + demo weather row.

**Step 2: Make recent help dynamic**

Load the latest 3 help records from local storage/service fallback instead of hardcoded cards.

**Step 3: Add featured story content on the home page**

Show a small “每日精选故事” section that reads from the community story service fallback.

**Step 4: Make profile page useful**

Replace static identity text and setting labels with real session data. Wire:
- accessibility settings → `PreferenceScreen(edit mode)`
- help record entry → `SeekerCenterScreen`
- logout → clear local session

### Task 4: Add fallback behavior to services used by the main frontend

**Files:**
- Modify: `linklab/lib/services/user_center/help_archive_service.dart`
- Modify: `linklab/lib/services/community/featured_story_service.dart`

**Step 1: Make help archive work without Supabase**

If Supabase is not initialized, read help history from `LocalStorage`, convert to `HelpRequestModel`, and compute basic statistics locally.

**Step 2: Make featured stories work without Supabase**

If Supabase is not initialized, return a small curated list of demo `FeaturedStory` entries so community/home surfaces are populated.

### Task 5: Verify build and record remaining PRD gaps

**Files:**
- Modify: `linklab/README.md`

**Step 1: Build web demo**

Run:
```powershell
& 'C:\Users\Administrator\tools\flutter\bin\flutter.bat' build web --release --base-href /LinkLab/
```

**Step 2: Update documentation**

Add a short note to `README.md` clarifying:
- what parts of the PRD are implemented in the current demo
- what still remains as future work

**Step 3: Summarize residual PRD gaps**

Keep the final audit explicit about the remaining non-trivial differences:
- real auth backend
- stable realtime matching backend
- production push notifications
- full SOS/voice/video/security infrastructure
