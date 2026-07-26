# Zen Mart Pro 🛒 - Multi-Vendor E-Commerce Ecosystem

Zen Mart Pro is a comprehensive, full-featured multi-vendor e-commerce platform built with Flutter and Firebase. It features dedicated portals for Customers, Vendors, Riders, and Super Admins, tied together with real-time data synchronization, secure Firebase authentication, and interactive capabilities like live chat, automated stock management, and unified branding.

## 🚀 Features by Role

### 1. Customer Portal 🛒
* **Browse & Discover**: View shops, search products, and filter items.
* **Shopping Cart & Checkout**: Seamless checkout flow with automatic stock verification and decrement.
* **Order Tracking**: Real-time order tracking logic from `Pending` all the way to `Delivered`.
* **Smart Interactivity**: Save items to a Wishlist.
* **Communication**: Real-time WhatsApp-style chat with Vendors and Riders, complete with image uploads and push notifications.
* **Reviews**: Rate and review products upon delivery.

### 2. Vendor Portal 🏪
* **Storefront Management**: Fully control Shop Profile and Shop Banners.
* **Product Catalog**: Add, edit, and organize products. Link products to custom categories.
* **Live Order Control**: Accept or reject incoming orders and update their statuses dynamically.
* **Real-time Comms**: Chat directly with customers to clarify order requirements (with real display names instead of emails!)
* **Analytics**: Basic vendor dashboard with revenue and review tracking.

### 3. Rider Portal 🏍
* **Delivery Hub**: View available active orders awaiting assignment.
* **Assignment Control**: Accept unassigned delivery requests (Pull system).
* **Delivery Flow**: Manage `Out for Delivery` and complete the order delivery lifecycle.
* **Direct Comms**: Chat directly with customers for address assistance.

### 4. Super Admin Portal 👑
* **Ecosystem Oversight**: Dashboard for all system-wide statistics.
* **Vendor & Shop Creation**: Create vendor accounts, enforce email verification, and assign storefronts.
* **Dispute & Complaint Handling**: Resolve platform-level complaints and monitor overall activity.

## ⚙️ Core Technologies & Shared Features
* **Framework**: Flutter (Dart) using Clean Architecture.
* **State Management**: Riverpod for predictable and scalable state injection.
* **Backend**: Firebase 
  * *Firebase Auth* (Email/Password, Role-based user claims)
  * *Cloud Firestore* (Real-time NoSQL streaming across all client apps)
  * *Firebase Storage* (Profile pictures, Product Photos, Chat Media)
  * *Firebase Cloud Messaging (FCM)* (Real-time push notifications for order updates and chat messages)
* **Custom Chat Engine**: Robust, natively integrated chat featuring image uploads via image_picker/firebase_storage and dynamic name fetching for conversational authenticity.

## 🛠 Setup Instructions

### Prerequisites
* Flutter SDK (`>=3.24.0`)
* Dart SDK (`>=3.5.0`)
* Android Studio (for Android builds) or Xcode (for iOS builds)
* An active Firebase Project configured for Android/iOS

### Installation
1. Clone this repository:
   ```bash
   git clone https://github.com/your-username/zen_mart_pro.git
   cd zen_mart_pro
   ```
2. Install package dependencies:
   ```bash
   flutter pub get
   ```
3. Connect Firebase:
   * Ensure your `firebase_options.dart`, `google-services.json` (Android), and `GoogleService-Info.plist` (iOS) are configured within the project mirroring your own Firebase backend.
4. Run the App:
   ```bash
   flutter run
   ```

### Quick Run / Admin Access
To bootstrap the application and define Super Admin credentials, you typically update the Firestore `users` collection to specify `role: 'super_admin'` for your primary user email.

---
_A ZenvyroLabs Initiative_
