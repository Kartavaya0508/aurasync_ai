### 🌿 AuraSync AI: Community-Driven Waste Intelligence

AuraSync AI is a professional-grade mobile application designed to bridge the gap between individual waste disposal and municipal logistics. By leveraging Google Gemini AI for instant classification and Supabase Realtime for geospatial syncing, AuraSync transforms passive waste management into an active, gamified community ecosystem.

This project directly addresses UN Sustainable Development Goals 12 (Responsible Consumption and Production) and 11 (Sustainable Cities and Communities).

🌎 Vision & Social Impact
In many urban environments, "leakage" occurs when specialized waste (E-waste, medical, toxic) is disposed of in general bins due to a lack of immediate information or collection logistics.

AuraSync AI solves this through:

Behavioral Change: Providing instant "Eco-Insights" at the moment of disposal to educate users on their environmental footprint.

Logistical Optimization: Using "Swarm Mapping" to allow citizens to identify waste hotspots for centralized collectors.

Gamified Sustainability: Incentivizing the diversion of toxic materials from landfills through a points-based ledger and local sector leaderboards.

🚀 Core Functionalities

1. Dual-Role Architecture
AuraSync features a dynamic routing gate that provides entirely different experiences based on user privileges:

Citizen Users: Scan waste, track personal impact, view leaderboards, and await local collection dispatches.

Collector Admins: View the macroscopic S2-Grid map, monitor waste density in real-time, and dispatch collection vehicles to high-yield sectors.

2. AI-Powered Waste Analysis
Utilizing Gemini 2.5 Flash-Lite, the app identifies waste items instantly via a live camera feed.

Classification: Automatically categorizes waste across dozens of parameters (E-waste, Chemical, Medical, etc.).

Toxicity Guard: Flags hazardous materials (like lithium-ion batteries or blister packs) with high-priority alerts.

Educational Overlay: Displays safe disposal tips and shocking eco-facts tailored to the specific item scanned.

3. The "Swarm" Map (Geospatial Sync)
Every verified scan is converted to a generalized Level 14 S2 Geometry Token to protect exact user locations while providing actionable data.

Real-time Visualization: Admins can view a heatmap of uncollected waste density across city sectors.

Active Ledgers: Users can manage their pending scans before the collector arrives.

4. Live Operations & Dispatch (Supabase Realtime)
When a Collector Admin dispatches a vehicle to a specific S2 Grid sector, AuraSync utilizes PostgreSQL triggers to instantly alert the community.

In-App Banners: Citizens in the targeted sector receive an immediate, animated floating notification warning them to prepare their waste.

Local Notifications: Fallback scheduled alarms (48h, 24h, 15m) trigger as the collection window approaches.

🛠️ Technical Architecture
Frontend: Flutter (v3.19.0+)

AI Engine: Google Generative AI (Gemini 2.5 Flash-Lite)

Backend & Auth: Supabase (PostgreSQL, Auth, Storage, Realtime Subscriptions)

Maps & Geo: Google Maps SDK, Google S2 Geometry Engine Logic

Environment Security: flutter_dotenv

🏃 Setup & Execution Guide
To maintain professional security standards, no API keys or database credentials are hardcoded in this repository. 

### Prerequisites

Ensure the Flutter SDK is installed and added to your PATH.

Obtain a Gemini API Key from Google AI Studio.

Initialize a Supabase Project and obtain your Project URL and Anon Key.

1. Clone the Repository
Bash

git clone https://github.com/YOUR_USERNAME/aurasync_ai.git
cd aurasync_ai
flutter pub get

2. Environment Setup (Crucial)
Create a file named exactly .env in the root directory of the project (at the same level as pubspec.yaml). Add your credentials:

Code snippet
SUPABASE_URL=your_actual_supabase_project_url
SUPABASE_ANON_KEY=your_actual_supabase_anon_key
GEMINI_API_KEY=your_actual_gemini_api_key
(Note: The .env file is intentionally ignored by git to protect your keys).

3. Database Schema Requirements
Your Supabase project must contain the following tables for the app to function:

profiles (id, display_name, avatar_url, role, trust_score)

waste_items (id, user_id, material_type, category, eco_points, weight_grams, status, s2_cell_id)

swarm_broadcasts (id, s2_cell_id, message, scheduled_time, status, ttl_expiry)

Ensure that Realtime (Replication) is toggled ON for the swarm_broadcasts table in your Supabase dashboard settings.

4. Run the Project

Bash

flutter run

👥 Core Team
Kartavya Jain - Lead Developer & Core Team Member at Google Developer Groups (GDG).
