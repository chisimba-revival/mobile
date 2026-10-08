# Mobile App UI Architecture & User Flows

## 1. LOGIN SCREEN (First Launch)
**Purpose**: Initial entry point requiring server configuration and credentials

```
┌─────────────────────────────────────────┐
│  FIELD SERVICE LOGIN                     │
│ ─────────────────────────────            │
│                                         │
│  Server URL:  [________________]        │
│  (e.g., https://api.chisimba.com)      │
│                                         │
│  Username:    [________________]        │
│  Password:    [________________]        │
│                                         │
│           [ Login ] [ Test Connection ] │
│                                         │
│  *Connection Status: ✅ SUCCESS         │
│                                         │
│  Or sign in to: North Reserve           │
│                                         │
│                    [Help] [About]       │
└─────────────────────────────────────────┘
```

**UI Elements**:
- Server URL input (text field with validation)
- Username input (text field)
- Password input (secure text field, obscured)
- Login button (primary action)
- Test Connection button (secondary)
- Connection status indicator (visual feedback)
- Error message display
- Context selection (if multiple available)
- Help/About links

---

## 2. DASHBOARD SCREEN (Main Hub)
**Purpose**: Central navigation point after login

```
┌─────────────────────────────────────────┐
│  FIELD SERVICE                      👤   │
├─────────────────────────────────────────┤
│  Welcome, John Smith                    │
│  Context: North Reserve    [Switch] ↓   │
├─────────────────────────────────────────┤
│                                         │
│  🗺️  ACTIVE OUTING                    │
│  ├─ Name: Morning Patrol               │
│  ├─ Status: In Progress                 │
│  ├─ Start: 08:00 AM                    │
│  └─ Time: 2h 15m                      │
│                                         │
│  [▶ Start New Outing]                  │
│                                         │
│ ─────────────────────────────           │
│  📋 MY SIGNOFFS                         │
│  ├─ Pending Review (3)                  │
│  ├─ Approved (5)                       │
│  └─ Needs Changes (1)                  │
│                                         │
│ ─────────────────────────────           │
│  🗺️  MAP VIEW                          │
│  [Toggle Map Type: Standard/Satellite] │
│  [Show My Path] [Show Outing Route]   │
│                                         │
│  📍 Current Location: 24.7755°E, 28.3319°S│
│  Last Update: 2 minutes ago            │
└─────────────────────────────────────────┘
```

**UI Elements**:
- Welcome header with user name
- Active outing card (if any)
- Quick stats/shortcuts
- Map preview with current location
- Pending sign-offs count
- Context switcher dropdown
- Navigation menu (bottom nav or drawer)

---

## 3. MAP & TRACKING SCREEN
**Purpose**: Real-time location tracking with path visualization

```
┌─────────────────────────────────────────┐
│  < Back │ FIELD SERVICE MAP           ≡ │
├─────────────────────────────────────────┤
│                                         │
│        [MAP VIEW - INTERACTIVE]        │
│                                         │
│   📍 User Position (Blue Dot)          │
│   ├─ Lat: 24.7755°E, Lng: 28.3319°S   │
│   ├─ Accuracy: ±5m                     │
│   └─ Updated: 30 seconds ago          │
│                                         │
│   🛤️ PATH TRACK                      │
│   ├─ Starting Point (Green Pin)       │
│   ├─ Current Point (Blue Dot)          │
│   ├─ Path Points (Red Line)           │
│   │   └─ 15 points recorded            │
│   └─ Distance: 3.2 km traveled         │
│                                         │
│   🎯 FEATURES                          │
│   ├─ [Center on Me] [Show All Paths]  │
│   ├─ [Start Recording] [Stop]         │
│   ├─ Zoom: +/- buttons                 │
│   └─ Layer Controls                    │
│                                         │
│  ───────────────────────────           │
│  [Save Path] [Clear Path]              │
└─────────────────────────────────────────┘
```

**UI Elements**:
- Interactive map (Google Maps / MapTiler)
- User location marker (blue dot)
- Path polyline/line (red/colored line)
- Location accuracy indicator
- Waypoint pins for outing features
 Control buttons (center, zoom, start/stop)
- Path recording indicators
- Distance/time tracking display
- Layer toggle (standard/satellite/terrain)
- Save path action
- Map type selector

---

## 4. OUTING LIST SCREEN
**Purpose**: Browse and manage recorded outings

```
┌─────────────────────────────────────────┐
│  < │ MY OUTINGS                      + │
├─────────────────────────────────────────┤
│  [Filter: All ▼]  [Sort: Date ▼]      │
├─────────────────────────────────────────┤
│                                         │
│  📍 Morning Patrol #147                │
│  │  └─ Started: 08:00 AM | Completed │
│  │     Duration: 2h 15m | Signoff: ✓  │
│  │     📷 3 photos                     │
│  │                                     │
│  📝 Sign-off: Approved by James T.     │
│  │     Comment: "Good work today!"    │
│                                         │
│  ───────────────────────────            │
│                                         │
│  📍 Afternoon Walk #146                │
│  │  └─ Started: 14:30 PM | Active    │
│  │     Duration: 1h 20m | Signoff: ⏳ │
│  │     📷 2 photos                     │
│                                         │
│  📝 Sign-off: Pending Review           │
│  │     Assigned to: James T.           │
│                                         │
│  ───────────────────────────            │
│                                         │
│  📍 Early Morning Survey #145          │
│  │  └─ Started: 06:00 AM | Completed │
│  │     Duration: 3h 45m                │
│  │     📷 15 photos                    │
│  │                                     │
│  📝 Sign-off: Needs Changes            │
│  │     Reviewer: Sarah P.             │
│                                         │
│  ───────────────────────────            │
│                                         │
│              [Load More]                │
└─────────────────────────────────────────┘
```

**UI Elements**:
- Scrollable outing list
- Filter/sort dropdowns (status, date)
- Status badges (In Progress, Completed, Pending Review, Approved, Rejected)
- Photo preview thumbnails
- Duration/time stamps
- Sign-off status and reviewer info
- Context indicators
- Load more button or infinite scroll
- "New Outing" FAB button

---

## 5. OUTING DETAIL SCREEN
**Purpose**: View and interact with a specific outing

```
┌─────────────────────────────────────────┐
│  < │ OUTING #147                       ⋮ │
│     └ Morning Patrol                    │
├─────────────────────────────────────────┤
│                                         │
│  ℹ️ OUTING DETAILS                     │
│  ├─ Name: Morning Patrol              │  │
│  ├─ Type: Guided Drive               │
│  ├─ Status: IN PROGRESS [Stop]        │
│  ├─ Started: 08:00 AM                  │
│  ├─ Elapsed: 2h 15m                    │
│  ├─ Context: North Reserve             │
│  └─ Participants: 12 guests            │
│                                         │
│  ───────────────────────────            │
│                                         │
│  📍 CURRENT LOCATION                   │
│  ├─ Coordinates: 24.7755°E, 28.3319°S│
│  ├─ Area: Savanna Plains               │
│  └─ Elevation: 1,245m                 │
│                                         │
│  🛤️ CURRENT PATH                      │
│  [Simple map preview or link to map]   │
│  └─ View Full Path [→]                │
│                                         │
│  ───────────────────────────            │
│                                         │
│  📝 SIGN-OFFS                          │
│  ├─ Approved: None                     │
│  ├─ Pending: None                      │
│  └─ Needs Changes: None                │
│                                         │
│  📷 MEDIA & EVIDENCE                   │
│  └─ 3 photos                           │
│     [View Gallery]                     │
│                                         │
│  ───────────────────────────            │
│                                         │
│  ✏️ ACTIONS                            │
│  [Edit] [End Outing] [Create Sign-off] │
└─────────────────────────────────────────┘
```

**UI Elements**:
- Outing header information
- Status display and control buttons
- Context/location details
- Current map/location preview
- Path visualization (mini map)
- Participant count
- Duration tracking
- Media gallery integration
- Sign-off status section
- Action buttons (Edit, End Outing, Create Sign-off)
- Back button / close

---

## 6. SIGN-OFF CREATION SCREEN
**Purpose**: Create a new field service sign-off for an outing

```
┌─────────────────────────────────────────┐
│  < │ CREATE SIGN-OFF                 × │
├─────────────────────────────────────────┤
│                                         │
│  📋 SIGN-OFF FOR:                      │
│  Morning Patrol #147                   │
│                                         │
│  ───────────────────────────            │
│                                         │
│  📝 SIGN-OFF TYPE                      │
│  └─ [Select Type ▼]                    │
│      Options: Wildlife Sighting,       │
│                Vehicle Check, Safety   │
│                Report, Incidents        │
│                                         │
│  ───────────────────────────            │
│                                         │
│  🗒️ DESCRIPTION                       │
│  [____________________________]         │
│  | Provide detailed description of      │
│  | what was observed or incidents       │
│  | encountered...                       │
│                                         │
│  📐 CATEGORIES/CRITERIA                │
│  └─ [Select Categories ▼]             │
│      (e.g., Wildlife, Safety,          │
│       Equipment, Guest Behavior)        │
│                                         │
│  ───────────────────────────            │
│                                         │
│  🎯 RATING/ASSESSMENT                   │
│  ├─ Wildlife Sighting: [5] ☆☆☆☆☆       │
│  ├─ Safety Compliance: [5] ☆☆☆☆☆      │
│  └─ Overall: [5] ☆☆☆☆☆                │
│                                         │
│  📷 EVIDENCE                           │
│  [Add Photo/Video] [View Media]        │
│                                         │
│  ───────────────────────────            │
│                                         │
│  ⏱️ TIMING                             │
│  ├─ Started: [Now]                     │
│  ├─ Ended: [Select Time]             │
│  └─ Duration: Auto-calculated          │
│                                         │
│  ───────────────────────────            │
│                                         │
│  [Submit for Review] [Save as Draft]   │
└─────────────────────────────────────────┘
```

**UI Elements**:
- Outing reference card
- Sign-off type selector
- Description text area
- Category multi-select
- Rating stars (1-5) for criteria
- Media upload section
- Timing controls
- Submit/Save buttons

---

## 7. SIGN-OFF REVIEW SCREEN (Mentor View)
**Purpose**: Review and approve sign-offs for mentors/managers

```
┌─────────────────────────────────────────┐
│  < │ REVIEW SIGN-OFFS                  │
├─────────────────────────────────────────┤
│                                         │
│  [Filter: Pending ▼] [Sort: Newest ▼] │
│                                         │
│  ───────────────────────────            │
│                                         │
│  🚨 #147 - Morning Patrol by John S.   │
│  ├─ Type: Wildlife Sighting            │
│  ├─ Status: PENDING REVIEW             │
│  ├─ Submitted: 2 days ago              │
│  ├─ Outing: #147                       │
│  │                                     │
│  │  [View Details] [Assign Review]     │
│  │                                     │
│  │  📝 Quick Review:                    │
│  │  └─ [5] ☆☆☆☆☆ [☑ Approve] [✗ Request Changes]│
│  │      [Comment...]                 │
│                                         │
│  ───────────────────────────            │
│                                         │
│  ⚠️ #146 - Safety Check by Lisa M.     │
│  ├─ Type: Incident Report              │
│  ├─ Status: PENDING REVIEW             │
│  ├─ Submitted: 1 week ago              │
│  │                                     │
│  │  [View Details] [Assign Review]     │
│  │                                     │
│  │  📝 Quick Review:                    │
│  │  └─ [4] ☆☆☆☆ [⬜] [✗ Request Changes]│
│  │      [Comment...]                 │
│                                         │
│  ───────────────────────────            │
│                                         │
│  ✅ #145 - Morning Survey by Sarah P.  │
│  ├─ Type: Vehicle Check               │
│  ├─ Status: APPROVED                  │
│  ├─ Approved: 3 days ago               │
│  │                                     │
│  │  [View] [Archive]                  │
│                                         │
│  ───────────────────────────            │
│                                         │
│              [Refresh List]            │
└─────────────────────────────────────────┘
```

**UI Elements**:
- Filter by status dropdown
- Sort options (newest, oldest, priority)
- Sign-off list with status indicators
- Quick action buttons (View, Assign, Review)
- Quick rating/approval for simple sign-offs
- Comment/instruction fields
- Outing links
- Media viewer integration
- Status badges

---

## 8. SETTINGS SCREEN
**Purpose**: App configuration and user preferences

```
┌─────────────────────────────────────────┐
│  < │ SETTINGS                          │
├─────────────────────────────────────────┤
│                                         │
│  👤 USER PROFILE                        │
│  ├─ Name: John Smith                  │
│  ├─ Email: john@example.com            │
│  ├─ Contexts: 2 available              │
│  └─ [Edit Profile]                     │
│                                         │
│  ───────────────────────────            │
│                                         │
│  🗺️ LOCATION SETTINGS                │
│  ├─ ☐ Enable Location Tracking         │
│  ├─ ☐ Auto-start Path Recording        │
│  ├─ ☐ High Accuracy Mode               │
│  ├─ Update Interval: 10 seconds        │
│  ├─ Track Points: Show path           │
│  └─ [Test Location]                    │
│                                         │
│  ───────────────────────────            │
│                                         │
│  🔄 SYNC SETTINGS                       │
│  ├─ Auto-sync: Enabled                │
│  ├─ Sync Interval: Every 5 minutes    │
│  ├─ Sync on Mobile Data: ✓            │
│  ├─ Conflict Resolution: Auto          │
│  └─ [Manual Sync Now]                  │
│                                         │
│  ───────────────────────────            │
│                                         │
│  📶 SERVER SETTINGS                     │
│  ├─ Server URL: https://api...        │
│  ├─ Test Connection                    │
│  └─ [Update Server]                    │
│                                         │
│  ───────────────────────────            │
│                                         │
│  🎨 APPEARANCE                          │
│  ├─ Theme: Auto                        │
│  │  (Light/Dark/System)                │
│  ├─ Language: English                    │
│  └─ Units: Metric (km, meters)         │
│                                         │
│  ───────────────────────────            │
│                                         │
│  ⓘ ABOUT                                │
│  ├─ App Version: 1.0.0                 │
│  ├─ Build: 20251006                    │
│  └─ [View Terms of Service] [Privacy] │
│                                         │
│  ───────────────────────────            │
│                                         │
│  [Sign Out] [About] [Help]             │
└─────────────────────────────────────────┘
```

**UI Elements**:
- User profile section with photo
- Location settings toggles
- Sync configuration options
- Server settings and connection test
- Appearance/theme selector
- Units system chooser
- About/version info
- Sign out button

---

## 9. CONTEXT SELECTOR SCREEN
**Purpose**: Choose from available contexts before starting work

```
┌─────────────────────────────────────────┐
│  < │ SELECT CONTEXT                    │
├─────────────────────────────────────────┤
│                                         │
│  🌍 AVAILABLE CONTEXTS                  │
│                                         │
│  ✅ NORTH RESERVE                      │
│  ├─ Your Role: Guide (Active)          │
│  ├─ Sign-offs: 2 available            │
│  └─ [Select] [View Details]            │
│                                         │
│  ⬜ SOUTH RESERVE                      │
│  ├─ Your Role: None                    │
│  ├─ Status: Not Assigned              │
│  │  └─ [Request Access]                │
│                                         │
│  ⬜ EAST RESERVE                       │
│  ├─ Your Role: Reviewer               │
│  ├─ Sign-offs: 0 pending              │
│  │  └─ [Select] [View Details]         │
│                                         │
│  ───────────────────────────            │
│                                         │
│       [Continue with Selected Context] │
└─────────────────────────────────────────┘
```

**UI Elements**:
- Context selection cards
- Role indicators (Guide, Mentor, Admin, Reviewer)
- Context status (Active, No Access, Pending)
- Request access button (for contexts with no access)
- Detailed context information

---

## 10. HELP SCREEN
**Purpose**: Provide users with guidance and support

```
┌─────────────────────────────────────────┐
│  < │ HELP & SUPPORT                    │
├─────────────────────────────────────────┤
│                                         │
│  📚 GETTING STARTED                     │
│  └─ [View Tutorial Video]              │
│                                         │
│  📖 USER GUIDE                         │
│  └─ [Read User Manual]                 │
│                                         │
│  ───────────────────────────            │
│                                         │
│  ❓ FREQUENTLY ASKED QUESTIONS          │
│  ├─ What is Field Service?             │
│  ├─ How do I create an outing?         │
│  ├─ How do I record my path?          │
│  ├─ How do I submit a sign-off?        │
│  └─ [More FAQs →]                      │
│                                         │
│  ───────────────────────────            │
│                                         │
│  💬 SUPPORT                             │
│  ├─ Email: support@example.com         │
│  ├─ Feedback: [Submit Feedback]        │
│  └─ Report Bug: [Report Issue]         │
│                                         │
│  ───────────────────────────            │
│                                         │
│  ⚖️ LEGAL                              │
│  ├─ [Terms of Service]                 │
│  ├─ [Privacy Policy]                   │
│  └─ [Licenses]                         │
│                                         │
│  ───────────────────────────            │
│                                         │
│       [Email Support] [Bug Report]     │
└─────────────────────────────────────────┘
```

**UI Elements**:
- Tutorial video embed
- User guide link
- FAQ section with expandable items
- Contact/support options
- Legal document links
- Feedback submission form
- Bug report form

---

## 11. NOTIFICATIONS SCREEN
**Purpose**: Display alerts, reminders, and updates

```
┌─────────────────────────────────────────┐
│  < │ NOTIFICATIONS                 🔔 │
├─────────────────────────────────────────┤
│  [All] [Unread]                        │
├─────────────────────────────────────────┤
│                                         │
│  🔴 UNREAD                              │
│  ├─ Sign-off Approved: #147           │
│  │  └─ Reviewed by James T. (2 min)   │
│  │     [View] [Dismiss]                │
│  │                                     │
│  │  📷 New Media: Outing #147           │
│  │  └─ 5 photos uploaded (10 min)     │
│  │     [View] [Dismiss]                │
│                                         │
│  ───────────────────────────            │
│                                         │
│  ✅ READ                                │
│  ├─ New Outing Assigned: #148         │
│  │  └─ Assigned by Sarah P. (1h)     │
│  │     [View] [Dismiss]                │
│                                         │
│  ├─ Path Sync: Completed              │
│  │  └─ All paths synced (3h)          │
│  │     [View]                         │
│                                         │
│  ───────────────────────────            │
│                                         │
│        [Mark All as Read]             │
└─────────────────────────────────────────┘
```

**UI Elements**:
- Unread/Read sections
- Notification cards with icons
- Action buttons (View, Dismiss)
- Grouped by type/color coding
- Mark all read button
- Notification filters

---

## 12. MAP LAYERS & FEATURES

**Map Layers**:

```
┌─────────────────────────────────────────┐
│  MAP LAYERS                             │
│ ───────────────────────────             │
│                                         │
│  📍 MAP BASE LAYERS                     │
│  ├─ ☐ Standard/Street View            │
│  ├─ ☐ Satellite View                  │
│  ├─ ✓ Terrain View (with contour)     │
│  └─ ☐ Hybrid                          │
│                                         │
│  ───────────────────────────            │
│                                         │
│  🗺️ OVERLAY LAYERS                    │
│  ├─ ☐ My Current Path (Active)        │
│  ├─ ☐ My Saved Paths                  │
│  │  └─ Today's path (recorded)        │
│  │  └─ Yesterday's path              │
│  │  └─ Last week's path              │
│  │                                     │
│  ├─ ☐ Outing Routes                   │
│  │  └─ Outing #147 route (red)        │
│  │  └─ Outing #146 route (blue)      │
│  │                                     │
│  ├─ ☐ Waypoints                       │
│  │  └─ Wildlife sighting points        │
│  │  └─ Guest drop-off points         │
│  │  └─ Rest/water stops               │
│  │                                     │
│  └─ ☐ Context Boundaries              │
│     └─ Highlight active context        │
│                                         │
│  ───────────────────────────            │
│                                         │
│  📊 ANALYTICS VIEW                      │
│  ├─ ☐ Heatmap (outings frequency)    │
│  ├─ ☐ Speed visualization             │
│  └─ ☐ Elevation profile               │
│                                         │
│       [Apply] [Clear All] [Cancel]     │
└─────────────────────────────────────────┘
```

**UI Elements**:
- Base map type selector (radio buttons)
- Overlay layers (toggle switches)
- Path visualization options
- Waypoint markers selector
- Analytics layer toggles
- Color scheme options
- Apply/Cancel buttons

---

## 13. OFFLINE MODE INDICATIONS

**Offline Status Display**:

```
┌─────────────────────────────────────────┐
│  📶 OFFLINE MODE                         │
│ ───────────────────────────             │
│                                         │
│  ❌ NO INTERNET CONNECTION             │
│                                         │
│  ⚡ OFFLINE CAPABILITIES ACTIVE:       │
│  ├─ ✓ View cached outings             │
│  ├─ ✓ View cached sign-offs           │
│  ├─ ✓ Record new outing paths          │
│  ├─ ✓ Save draft sign-offs             │
│  ├─ ✗ Upload media (queued)            │
│  └─ ✗ Submit sign-offs (queued)        │
│                                         │
│  ───────────────────────────            │
│                                         │
│  📋 PENDING CHANGES (3):               │
│  ├─ Outing #148 - Path recording      │
│  └─ Sign-off for outing #148          │
│                                         │
│  🔄 Will sync when connection returns   │
│  Progress: 5% (est. 2 mins)            │
│                                         │
│  [Check Connection] [Manage Queue]     │
└─────────────────────────────────────────┘
```

**UI Elements**:
- Offline status banner/icon
- Available offline capabilities list
- Pending changes list
- Sync progress indicator
- Sync now button (if available)
- Offline cache statistics

---

## SUMMARY OF USER INTERFACE SCREENS

| Screen | Purpose | Key Features | Backend Integration |
|--------|---------|-------------|-------------------|
| **Login** | Authentication | Server URL, username, password, login button | ✅ JWT auth flow |
| **Dashboard** | Main hub | Active outing, stats, context switch | ✅ Outing listing |
| **Map** | Location tracking | Real-time map, path display, waypoints | ✅ Geolocation service |
| **Outing List** | Browse outings | Filters, sorting, status indicators | ✅ Outing listing |
| **Outing Detail** | View specific outing | Details, edit, end, sign-offs | ✅ Outing CRUD |
| **Sign-off Create** | Create sign-off | Description, ratings, media, submit | ✅ Sign-off creation |
| **Sign-off Review** | Review sign-offs | Approve, request changes, comments | ✅ Review workflows |
| **Settings** | Configuration | Location, sync, server, appearance | ✅ User preferences |
| **Context Select** | Choose context | Multi-context selection, roles | ✅ Context claims |
| **Help** | Support | Tutorials, FAQs, contact, legal | ✅ Static content |
| **Notifications** | Alerts | Push notifications, read status | ✅ Notification API |

---

## IMPLEMENTATION PRIORITY ORDER

### Sprint 1 (MVP):
1. ✅ Login Screen (Backend ready)
2. ✅ Context Selector (Backend ready)
3. ✅ Outing List Screen (Backend ready)
4. ✅ Map with Tracking (Backend ready)
5. ✅ Outing Detail Screen (Backend ready)

### Sprint 2 (Enhanced):
6. ✅ Sign-off Creation (Backend ready)
7. ✅ Sign-off Review (Backend ready)
8. ✅ Settings Screen (Core UI)
9. ✅ Notifications (Backend ready)

### Sprint 3 (Advanced):
10. ✅ Help Screen (Frontend only)
11. ✅ Reporting Screen (Analytics)
12. ✅ Admin Screen (Admin features)

---

This structure provides a complete mobile app experience for field service management with proper location tracking, path recording, and outing management capabilities.

Each screen is designed to integrate with the existing Chisimba backend API which has already been implemented and tested.