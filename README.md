🌿 AuraSync AI: A Community-Driven Waste Intelligence Ecosystem
AuraSync AI is a professional-grade mobile application designed to bridge the gap between individual waste disposal and municipal logistics. By leveraging Google Gemini AI and real-time geospatial syncing, AuraSync transforms passive waste management into an active, gamified community experience.

This project directly addresses UN Sustainable Development Goal 12 (Responsible Consumption and Production) and SDG 11 (Sustainable Cities and Communities).

🌎 Vision & Social Impact
In many urban environments, "leakage" occurs when specialized waste (E-waste, medical, toxic) is disposed of in general bins due to a lack of immediate information or collection logistics.

AuraSync AI solves this through:

Behavioral Change: Providing instant "Eco-Insights" at the moment of disposal to educate users on environmental footprints.

Logistical Optimization: Using "Swarm Mapping" to allow citizens to identify waste hotspots for collectors.

Gamified Sustainability: Incentivizing the diversion of toxic materials from landfills through a points-based leaderboard system.

🚀 Core Functionalities
1. AI-Powered Waste Analysis
Utilizing Gemini 1.5 Flash-Lite, the app identifies waste items via a camera feed.

Classification: Automatically categorizes waste (Plastic, Metal, E-waste, Medical, etc.).

Toxicity Guard: Flags hazardous materials (like lithium-ion batteries or blister packs) with high-priority alerts.

Educational Overlay: Displays a "Safe Disposal Tip" and a "Shocking Eco-Fact" for every scanned item.

2. The "Swarm" Map (Geospatial Sync)
Every scanned item is geo-tagged and synchronized to a central Supabase database.

Real-time Visualization: Users can view a "Swarm Map" of uncollected waste in their neighborhood.

Collective Impact: This data allows municipal authorities or community groups to see where specialized pickups are most needed.

3. Impact Dashboard & Leaderboards
Community Goal: A real-time progress bar shows how close the neighborhood is to its monthly waste diversion target (e.g., 100kg).

Personal Stats: Tracks individual contributions in kilograms and "Eco-Points."

4. Smart Push Notifications
Request Loop: Users receive an instant confirmation when they log a pickup request.

Logistics Alerts: A scheduled notification (Local Push) alerts users 48 hours before a specialized collector is set to arrive in their "Swarm" zone.

🛠️ Technical Architecture
Frontend: Flutter (v3.19.0+)

AI Logic: Google Generative AI (Gemini 1.5 Flash)

Backend & Auth: Supabase (PostgreSQL with Real-time listeners)

Maps: Google Maps SDK for Android

Infrastructure: Kotlin DSL (Gradle) with Core Library Desugaring for modern Java API support on older devices.

🏃 Setup & Execution Guide
To maintain professional security standards, no API keys or database credentials are hardcoded. All keys are injected at runtime via --dart-define.

1. Prerequisites
Ensure the Flutter SDK is installed and added to your PATH.

Obtain a Gemini API Key from Google AI Studio.

Initialize a Supabase Project and obtain your Project URL and Anon Key.

2. Installation
Clone the repository and fetch the required packages:

Bash
git clone https://github.com/YOUR_USERNAME/aurasync_ai.git
cd aurasync_ai
flutter pub get
3. Running the Project
Use the following command to launch the app on your connected device/emulator. Replace the placeholders with your actual credentials:

Bash
flutter run \
  --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE \
  --dart-define=SUPABASE_URL=YOUR_URL_HERE \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY_HERE
4. Building for Production (APK)
To generate a release-ready APK for the Google Solution Challenge submission:

Bash
flutter build apk --release \
  --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE \
  --dart-define=SUPABASE_URL=YOUR_URL_HERE \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY_HERE
🛡️ Security Best Practices
AuraSync AI follows industry-standard security protocols. By utilizing String.fromEnvironment, we ensure that:

Zero-Key Leakage: Private keys are never committed to version control.

Environment Isolation: Production and development keys can be swapped without modifying the source code.

Evaluator Privacy: Evaluators can safely run the app using their own sandbox keys.

👥 Core Team
Kartavya Jain - Lead Developer & Core Team Member at Google Developer Groups (GDG).
