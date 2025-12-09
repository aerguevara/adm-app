# Firebase Admin App 🔥

iOS admin interface for managing Firebase Firestore collections with full CRUD operations.

## 📱 Features

- **Users Management** - Create, view, edit, and delete user profiles with levels and XP
- **Feed Administration** - Manage activity feed items with types and rarity levels
- **Territory Control** - Administer geographic territories with boundary coordinates
- **Real-time Updates** - Pull-to-refresh functionality on all views
- **Search & Filter** - Find data quickly with search bars and type filters
- **Native iOS Design** - Built with SwiftUI for a modern, native experience

## 🎨 UI/UX improvements in progress

To address the audit findings and streamline day-to-day admin work, the app roadmap now includes:

- **Navigation & visibility**
  - Tab bar with blurred background and clear active pill to anchor context switching.
  - Persisted, on-canvas filters (chips/segments) per section so active filters are always visible.

- **Safer bulk actions**
  - Destructive operations (Delete All, Borrado maestro) moved into an overflow/⚠️ menu or footer banner, away from primary actions.
  - Individual user resets demoted to swipe/context menus to reduce accidental taps.

- **Consistent cards & chips**
  - Unified chip style for type, rarity, XP, level, and status across Users, Feed, and Territories.
  - Activity and feed cards reorganized so headers show avatar + user context with a single row of chips (rareza/tipo/XP) and territory impacts highlighted with icons.

- **Loading, empty, and feedback states**
  - Light overlay spinners instead of full replacements, keeping previous content visible during loads.
  - Empty states upgraded with CTAs ("Agregar feed", "Crear actividad") plus optional illustrations.
  - Toasts/banners for success and error messaging on bulk operations.

- **Cross-links & density controls**
  - Quick links from activities/territories to related feeds and recent territory activity.
  - Toggle between grid and compact list layouts for Users and Feed to balance density vs. readability.

## 🗂️ Collections

### Users
- Display Name
- Email
- Level & XP
- Join Date & Last Updated

### Feed
- Title & Subtitle
- Type (Territory Conquered, Level Up, Achievement, etc.)
- Rarity (Common, Rare, Epic, Legendary)
- XP Earned
- Personal/Shared status

### Remote Territories
- Center Coordinates (Latitude/Longitude)
- Boundary Points (polygon)
- Expiration Date
- Active/Expired Status

## 🚀 Setup

### Prerequisites
- Xcode 15+
- iOS 17.0+
- Firebase account

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/aerguevara/adm-app.git
   cd adm-app
   ```

2. **Install Firebase SDK**
   - Open `adm-app.xcodeproj` in Xcode
   - Go to **File → Add Package Dependencies**
   - Add: `https://github.com/firebase/firebase-ios-sdk`
   - Select: `FirebaseFirestore` and `FirebaseFirestoreSwift`

3. **Add Firebase Configuration**
   - Download `GoogleService-Info.plist` from [Firebase Console](https://console.firebase.google.com/)
   - Drag it into the `adm-app` folder in Xcode
   - Ensure "Copy items if needed" is checked

4. **Build and Run**
   ```
   Cmd + B to build
   Cmd + R to run
   ```

For detailed setup instructions, see [SETUP.md](SETUP.md)

## 📂 Project Structure

```
adm-app/
├── Models/              # Data models (User, FeedItem, RemoteTerritory)
├── Services/            # FirebaseManager service
├── Views/
│   ├── Users/          # User CRUD views
│   ├── Feed/           # Feed CRUD views
│   ├── Territories/    # Territory CRUD views
│   └── MainAdminView   # Tab navigation
└── Utils/              # Constants, Extensions
```

## 🛠️ Tech Stack

- **SwiftUI** - Modern declarative UI framework
- **Firebase Firestore** - Cloud NoSQL database
- **Async/Await** - Modern Swift concurrency
- **MVVM Architecture** - Clean separation of concerns

## 📸 Screenshots

The app features three main tabs:
- 👥 **Users** - Manage user profiles
- 📰 **Feed** - Control activity feed
- 🗺️ **Territories** - Administer geographic zones

## 🔒 Security

⚠️ **Important**: Update Firestore security rules before production deployment!

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 📝 License

This project is private and proprietary.

## 👨‍💻 Author

**Anyelo Reyes Guevara**
- GitHub: [@aerguevara](https://github.com/aerguevara)

---

Built with ❤️ using SwiftUI and Firebase
