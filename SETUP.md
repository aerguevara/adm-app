# Firebase Admin App - Setup Instructions

## Prerequisites
- Xcode 15 or later
- iOS 17.0 or later
- Firebase account with an existing project
- Access to Firebase Console

## Setup Steps

### 1. Install Firebase SDK

1. Open `adm-app.xcodeproj` in Xcode
2. Go to **File → Add Package Dependencies...**
3. Enter the Firebase SDK URL: `https://github.com/firebase/firebase-ios-sdk`
4. Select version: **10.0.0** or later (use latest)
5. Add the following packages:
   - `FirebaseFirestore`
   - `FirebaseFirestoreSwift`

### 2. Add GoogleService-Info.plist

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Click on **Add app** → **iOS**
4. Register your app with bundle identifier: `com.aerguevara.adm-app` (or your custom bundle ID)
5. Download the `GoogleService-Info.plist` file
6. Drag and drop it into your Xcode project's `adm-app` folder
7. **Important**: Make sure "Copy items if needed" is checked and the target is selected

### 3. Verify Project Structure

Your project should now have this structure:

```
adm-app/
├── Models/
│   ├── User.swift
│   ├── FeedItem.swift
│   └── RemoteTerritory.swift
├── Services/
│   └── FirebaseManager.swift
├── Views/
│   ├── Users/
│   │   ├── UsersListView.swift
│   │   ├── UserDetailView.swift
│   │   └── AddUserView.swift
│   ├── Feed/
│   │   ├── FeedListView.swift
│   │   ├── FeedDetailView.swift
│   │   └── AddFeedView.swift
│   ├── Territories/
│   │   ├── TerritoriesListView.swift
│   │   ├── TerritoryDetailView.swift
│   │   └── AddTerritoryView.swift
│   └── MainAdminView.swift
├── Utils/
│   ├── Constants.swift
│   └── Extensions.swift
├── adm_appApp.swift
└── GoogleService-Info.plist  ← Must be added!
```

### 4. Configure Firebase Firestore

1. In Firebase Console, go to **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (for development)
   - **Warning**: Don't forget to update security rules for production!
4. Select a location closest to you

### 5. Build and Run

1. Select a simulator or device in Xcode
2. Press **Cmd + B** to build
3. If build succeeds, press **Cmd + R** to run
4. The app should launch with three tabs: Users, Feed, Territories

## Troubleshooting

### "Firebase not configured" error
- Make sure `GoogleService-Info.plist` is added to the project
- Verify it's included in the app target
- Clean build folder: **Product → Clean Build Folder**

### Package resolution issues
- Try: **File → Packages → Reset Package Caches**
- Update packages: **File → Packages → Update to Latest Package Versions**

### Build errors
- Make sure all files are added to the target
- Check that iOS deployment target is 17.0 or later
- Verify Swift version is 5.9 or later

## Security Rules (Production)

Before deploying to production, update your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only allow authenticated users
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Next Steps

1. Test creating, reading, updating, and deleting documents in each collection
2. Verify data appears correctly in Firebase Console
3. Add authentication if needed
4. Customize UI as desired
