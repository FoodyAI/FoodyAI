# 🔔 Push Notification Implementation - Kanban Board

## Project Overview
Implement Firebase Cloud Messaging (FCM) push notifications with AWS RDS database integration, supporting filtered notifications to specific user segments (premium users, age groups, notification preferences).

---

## 📋 BACKLOG

### Issue #1: Database Schema Setup
**Priority:** 🔴 Critical
**Assignee:** Developer 1
**Estimated Time:** 2-3 hours
**Blocks:** #2, #3, #4, #5

**Description:**
Update the PostgreSQL database schema to support FCM tokens and notification preferences.

**Tasks:**
- [ ] Create `push-notification-schema.sql` file
- [ ] Add FCM token column to users table
- [ ] Add notification preferences columns (notifications_enabled, is_premium)
- [ ] Create notifications_log table for tracking sent notifications
- [ ] Create notification_campaigns table for bulk notifications
- [ ] Add indexes for performance optimization
- [ ] Create triggers for token update timestamps
- [ ] Test schema with sample queries

**Acceptance Criteria:**
- All tables and columns created successfully
- Indexes are properly set up
- Triggers work correctly
- Sample queries return expected results

**SQL Changes:**
```sql
ALTER TABLE users ADD COLUMN fcm_token TEXT;
ALTER TABLE users ADD COLUMN notifications_enabled BOOLEAN DEFAULT true;
ALTER TABLE users ADD COLUMN is_premium BOOLEAN DEFAULT false;
CREATE TABLE notifications_log (...);
CREATE TABLE notification_campaigns (...);
```

**Dependencies:** None
**Related Issues:** Blocks all other issues

---

### Issue #2: Firebase Admin SDK Setup (Lambda)
**Priority:** 🔴 Critical
**Assignee:** Developer 2
**Estimated Time:** 2-3 hours
**Depends On:** #1
**Blocks:** #4, #5

**Description:**
Set up Firebase Admin SDK in AWS Lambda for sending push notifications from the backend.

**Tasks:**
- [ ] Download Firebase Admin SDK service account key from Firebase Console
- [ ] Store service account key securely in AWS Lambda environment
- [ ] Create Lambda layer for firebase-admin package
- [ ] Initialize Firebase Admin SDK in Lambda function
- [ ] Test Firebase Admin SDK connection
- [ ] Create helper functions for sending notifications

**Acceptance Criteria:**
- Firebase Admin SDK properly initialized
- Can send test notification successfully
- Service account key securely stored
- Error handling implemented

**Required Files:**
- Service account JSON key (from Firebase Console)
- Lambda environment variables setup

**Dependencies:** Issue #1
**Related Issues:** Required by #4, #5

---

### Issue #3: Flutter FCM Service Implementation
**Priority:** 🔴 Critical
**Assignee:** Developer 1
**Estimated Time:** 3-4 hours
**Depends On:** #1
**Blocks:** #6, #7

**Description:**
Implement Flutter service for handling FCM token registration and notification receiving.

**Tasks:**
- [ ] Create `lib/services/notification_service.dart`
- [ ] Initialize FirebaseMessaging in Flutter app
- [ ] Request notification permissions (iOS & Android)
- [ ] Get and store FCM token locally
- [ ] Send FCM token to AWS backend
- [ ] Handle token refresh
- [ ] Implement foreground notification handling
- [ ] Implement background notification handling
- [ ] Handle notification tap actions

**Acceptance Criteria:**
- FCM token successfully retrieved and stored
- Token sent to backend on user login
- Foreground notifications display correctly
- Background notifications work properly
- Notification tap navigation works

**Files to Create:**
- `lib/services/notification_service.dart`
- Update `lib/main.dart` for initialization

**Dependencies:** Issue #1
**Related Issues:** Blocks #6, #7

---

## 🏗️ IN PROGRESS

### Issue #4: Lambda Function - Send Notification Endpoint
**Priority:** 🟡 High
**Assignee:** Developer 2
**Estimated Time:** 4-5 hours
**Depends On:** #1, #2
**Blocks:** #5

**Description:**
Create AWS Lambda function that sends push notifications to filtered users based on criteria.

**Tasks:**
- [ ] Create `aws-lambda/send-notification/index.js`
- [ ] Implement database query functions for user filtering
- [ ] Create filter logic (all users, premium, age-based, etc.)
- [ ] Implement FCM message sending with Firebase Admin SDK
- [ ] Add error handling and retry logic
- [ ] Log notifications to notifications_log table
- [ ] Add rate limiting to prevent spam
- [ ] Create API Gateway endpoint

**Acceptance Criteria:**
- Can send notification to single user
- Can send bulk notifications to filtered users
- Supports multiple filter types (premium, age, custom)
- All sent notifications logged in database
- Proper error handling and logging
- API endpoint secured with authentication

**Filter Types to Support:**
```javascript
{
  "type": "all",           // All users with notifications enabled
  "type": "premium",       // Premium users only
  "type": "age",           // Users with age < X or age > X
  "type": "custom",        // Custom SQL WHERE clause
  "userIds": ["id1", "id2"] // Specific user IDs
}
```

**Dependencies:** Issues #1, #2
**Related Issues:** Required by #5

---

### Issue #5: Lambda Function - Notification Campaign Manager
**Priority:** 🟢 Medium
**Assignee:** Developer 2
**Estimated Time:** 3-4 hours
**Depends On:** #1, #2, #4

**Description:**
Create Lambda function for creating, scheduling, and managing notification campaigns.

**Tasks:**
- [ ] Create `aws-lambda/notification-campaigns/index.js`
- [ ] Implement campaign CRUD operations (Create, Read, Update, Delete)
- [ ] Add campaign scheduling functionality
- [ ] Integrate with send-notification function
- [ ] Track campaign statistics (sent, delivered, failed)
- [ ] Create campaign status management
- [ ] Add API Gateway endpoints

**Acceptance Criteria:**
- Can create draft campaigns
- Can schedule campaigns for future sending
- Campaign statistics tracked accurately
- Campaign status properly managed
- API endpoints work correctly

**API Endpoints:**
- POST /campaigns - Create campaign
- GET /campaigns - List campaigns
- GET /campaigns/{id} - Get campaign details
- PUT /campaigns/{id} - Update campaign
- DELETE /campaigns/{id} - Delete campaign
- POST /campaigns/{id}/send - Send campaign immediately

**Dependencies:** Issues #1, #2, #4
**Related Issues:** Uses #4

---

### Issue #6: Flutter Notification Preferences UI
**Priority:** 🟢 Medium
**Assignee:** Developer 1
**Estimated Time:** 3-4 hours
**Depends On:** #3

**Description:**
Create UI for users to manage their notification preferences in the Profile screen.

**Tasks:**
- [ ] Add notification settings section to Profile View
- [ ] Create toggle for enabling/disabling notifications
- [ ] Add notification type preferences (promotional, updates, etc.)
- [ ] Implement save functionality to update AWS backend
- [ ] Show current notification status
- [ ] Handle permission requests gracefully
- [ ] Add visual feedback for changes

**Acceptance Criteria:**
- Users can enable/disable notifications
- Changes saved to AWS database
- UI updates reflect current status
- Permission prompts handled correctly
- Visual feedback on save

**Files to Update:**
- `lib/presentation/pages/profile_view.dart`
- `lib/presentation/viewmodels/user_profile_viewmodel.dart`

**Dependencies:** Issue #3
**Related Issues:** Works with #3

---

## 🔍 IN REVIEW

### Issue #7: Update AWS User Profile Service
**Priority:** 🔴 Critical
**Assignee:** Developer 1
**Estimated Time:** 2 hours
**Depends On:** #1, #3

**Description:**
Update existing AWS user profile Lambda and Flutter service to handle FCM token and notification preferences.

**Tasks:**
- [ ] Update `aws-lambda/user-profile/index.js` to accept fcm_token
- [ ] Add notifications_enabled field handling
- [ ] Add is_premium field handling
- [ ] Update Flutter `lib/services/aws_service.dart`
- [ ] Add method to update FCM token
- [ ] Add method to update notification preferences
- [ ] Update user profile model to include new fields

**Acceptance Criteria:**
- Backend accepts and stores FCM tokens
- Backend handles notification preferences
- Flutter can update FCM token on login
- Flutter can update notification preferences
- All changes backward compatible

**Files to Update:**
- `aws-lambda/user-profile/index.js`
- `lib/services/aws_service.dart`
- `lib/domain/entities/user_profile.dart`
- `lib/data/models/user_profile.dart`

**Dependencies:** Issues #1, #3
**Related Issues:** Works with #3

---

## ✅ DONE

_(No issues completed yet)_

---

## 🧪 TESTING

### Issue #8: Testing & Documentation
**Priority:** 🟢 Medium
**Assignee:** Both Developers
**Estimated Time:** 2-3 hours
**Depends On:** All previous issues

**Description:**
Comprehensive testing of the push notification system and documentation.

**Tasks:**
- [ ] Test single user notification sending
- [ ] Test bulk notification with filters (premium, age)
- [ ] Test notification receiving on Flutter (foreground/background)
- [ ] Test notification tap navigation
- [ ] Test token refresh scenarios
- [ ] Test campaign scheduling
- [ ] Test permission handling on iOS & Android
- [ ] Create user documentation
- [ ] Create developer documentation
- [ ] Add troubleshooting guide

**Test Scenarios:**
1. **Single User Notification**
   - Send notification to one user
   - Verify received on device
   - Check notification_log entry

2. **Bulk Notification - Premium Users**
   - Mark 3 users as premium
   - Send notification to premium users only
   - Verify only premium users receive it

3. **Bulk Notification - Age Filter**
   - Send to users under 30
   - Verify correct users receive it

4. **Foreground Notification**
   - App open, receive notification
   - Verify notification displays

5. **Background Notification**
   - App closed, receive notification
   - Tap notification, verify navigation

6. **Token Refresh**
   - Force token refresh
   - Verify updated in database

**Dependencies:** All previous issues
**Related Issues:** Final validation of all issues

---

## 📊 Issue Dependency Graph

```
┌─────────────────────────────────────────────────────────────┐
│                     Issue #1: Database Schema                │
│                         (CRITICAL)                           │
└──────────────────────┬──────────────────┬───────────────────┘
                       │                  │
       ┌───────────────┴────────┐    ┌────┴──────────────┐
       │                        │    │                   │
┌──────▼─────────┐    ┌────────▼────▼──────┐    ┌───────▼────────┐
│  Issue #2:     │    │    Issue #3:       │    │   Issue #7:    │
│  Firebase      │    │  Flutter FCM       │    │  Update User   │
│  Admin SDK     │    │    Service         │    │   Profile      │
│  (CRITICAL)    │    │   (CRITICAL)       │    │  (CRITICAL)    │
└────────┬───────┘    └─────┬──────────────┘    └────────────────┘
         │                  │
         │                  │
    ┌────▼──────────────────▼─────┐
    │     Issue #4: Send           │
    │  Notification Lambda         │
    │        (HIGH)                │
    └───────────┬──────────────────┘
                │
         ┌──────▼──────────┐
         │   Issue #5:     │
         │   Campaign      │
         │   Manager       │
         │   (MEDIUM)      │
         └─────────────────┘

         ┌─────────────────┐
         │   Issue #6:     │
         │  Notification   │
         │  Preferences UI │
         │   (MEDIUM)      │
         └─────────────────┘

                ▼
    ┌───────────────────────┐
    │    Issue #8:          │
    │    Testing &          │
    │   Documentation       │
    │     (MEDIUM)          │
    └───────────────────────┘
```

---

## 🎯 Suggested Work Distribution

### Developer 1 (Flutter/Mobile Focus)
1. Issue #1: Database Schema Setup
2. Issue #3: Flutter FCM Service Implementation
3. Issue #6: Flutter Notification Preferences UI
4. Issue #7: Update AWS User Profile Service (Flutter part)
5. Issue #8: Testing (Flutter side)

### Developer 2 (Backend/Lambda Focus)
1. Issue #2: Firebase Admin SDK Setup
2. Issue #4: Lambda Function - Send Notification Endpoint
3. Issue #5: Lambda Function - Notification Campaign Manager
4. Issue #7: Update AWS User Profile Service (Lambda part)
5. Issue #8: Testing (Backend side)

---

## 📅 Recommended Sprint Plan

### Sprint 1 (Week 1): Foundation
- **Day 1-2:** Issues #1, #2 (Both developers)
- **Day 3-4:** Issue #3 (Developer 1), Issue #4 (Developer 2)
- **Day 5:** Issue #7 (Both developers collaborate)

### Sprint 2 (Week 2): Features & Polish
- **Day 1-2:** Issue #6 (Developer 1), Issue #5 (Developer 2)
- **Day 3-5:** Issue #8 (Both developers - testing and documentation)

---

## 🚀 Quick Start Priority Order

1. ✅ **Issue #1** - Database Schema (Start here!)
2. ✅ **Issue #2** - Firebase Admin SDK (Parallel with #1)
3. ✅ **Issue #3** - Flutter FCM Service
4. ✅ **Issue #7** - Update User Profile Service
5. ✅ **Issue #4** - Send Notification Lambda
6. ✅ **Issue #6** - Notification Preferences UI
7. ✅ **Issue #5** - Campaign Manager
8. ✅ **Issue #8** - Testing & Documentation

---

## 📝 Notes
- All Lambda functions need proper IAM roles and permissions
- Firebase Admin SDK requires service account JSON key
- Test on both iOS and Android devices
- Consider rate limiting for notification sending
- Monitor CloudWatch logs for debugging
- Keep notification payload under 4KB limit
