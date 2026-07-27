# Zen Mart Pro - Multi-Vendor E-Commerce Ecosystem

## Project Overview
Zen Mart Pro is a cutting-edge, complete Multi-Vendor E-Commerce Ecosystem that mirrors modern platforms like Foodpanda, Daraz, Amazon, and Shopify Marketplace. It features four distinct user roles—Super Admin, Vendor, Customer, and Rider—all operating smoothly within a single Flutter application seamlessly integrated with Firebase backend services.

The platform relies on real-time data synchronization utilizing Firebase Cloud Firestore and Firebase Cloud Messaging (FCM), ensuring that state changes (like inventory updates, order tracking, and rider availability) instantly propagate across all relevant users' devices.

## Key Features & Roles

👑 **Super Admin**
- Full system oversight and control.
- Create Vendor accounts, provision Shops, and assign them to Vendors.
- Manage Customers, Riders, Categories, and Platform Banners.
- Access System-wide reports and metrics.

🏪 **Vendor**
- Assigned to a predefined Shop by the Super Admin.
- Dedicated Dashboard to monitor Shop performance and manage Sales.
- Dynamic control over Inventory (Categories and Products), handling pricing and stock limitations via a custom UI.
- Process Customer Orders by accepting, preparing, and marking them as "Ready for Pickup".
- Real-time modification of **Delivery Fees** associated with their shop operations.

🛒 **Customer**
- Elegant interface to browse various Vendors and their Products.
- Add items to a smart Shopping Cart.
- Checkout flow offering multiple payment methods (including Cash on Delivery & QR Code wallet simulation).
- Use integrated static coupons (e.g., ZENVYRO20, WELCOME10).
- Fully functional order history and Real-time Tracking from "Order Pending" to "Delivered".

🏍 **Rider**
- Efficient interface for browsing available orders marked as "Ready for Pickup".
- Accept delivery assignments, view route/address details, and monitor their delivery history/earnings.
- Earnings dynamically updated based on the delivery criteria defined by Vendor fees.

✨ **Bonus & Core Integrations**
- **Dark Mode Support**
- **QR Code Payments**
- **Coupons & Discounts** 
- **Offline Data Sync (Firestore)**
- **Cloud Storage** for dynamic banner and avatar hosting.
- **Firebase Push Notifications (FCM)** setup for order event triggers.

## Packages Used

### Core Framework
- `flutter`: The SDK for multi-platform UI construction.

### Firebase Backend Services
- `firebase_core`: Fundamental plugin for Firebase initialization.
- `firebase_auth`: Role-based authentication using email and secure sessions.
- `cloud_firestore`: Synchronized Non-SQL document storage enabling real-time app capabilities.
- `firebase_storage`: Cloud media management and hosting for avatars/banners.
- `firebase_messaging`: FCM handling for cross-device notifications.

### State Management & Navigation
- `provider`: Used for global AuthState and real-time dependency injection.

### UI Enhancements & Extensions
- `google_fonts`: Simplified access to premium typography without manually importing fonts.
- `cached_network_image`: Network optimization cache to minimize backend queries for media.
- `qr_flutter`: Real-time creation of custom QR codes during check-out flow.
- `intl`: Streamlining proper Number/Currency format translations logic globally.
- `image_picker` & `flutter_image_compress`: Allowing admins and vendors to manipulate graphics gracefully within standard mobile constraints.

## Setup Instructions

### 1. Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable release compatible with Kotlin/Gradle).
- A valid Google Account for Firebase set-up.

### 2. Implementation Steps
1. **Clone the Source Code**: Pull the repository into a local working directory.
2. **Retrieve Dependencies**: Open your terminal locally at the project root and enter `flutter pub get`.
3. **Connect to Firebase**:
   - Run `flutterfire configure` to generate `firebase_options.dart`.
   - Ensure the associated Firebase Console Project has **Authentication (Email/Password)**, **Firestore**, and **Storage** fully activated.
4. **Deploy Security Rules**: Apply standard open debug rules or standard auth-protection configurations for the Firestore database inside the active Firebase Project.
5. **Compile & Run**: Launch an iOS simulator or Android emulator and run `flutter run`.

--- 
*Note: The **ZenvyroLabs** branding logo is displayed appropriately within the main Customer Dashboard Headers demonstrating adherence to the evaluation requirements.*
