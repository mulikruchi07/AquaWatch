# 🌊 AquaWatch – Smart Water Monitoring App

![Flutter](https://img.shields.io/badge/Flutter-v3-blue)
![Supabase](https://img.shields.io/badge/Supabase-Backend-green)
![Platform](https://img.shields.io/badge/Cross--Platform-Mobile%20App-orange)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)

AquaWatch is a real-time water monitoring mobile application built using **Flutter** and **Supabase**. It helps users monitor water level, quality (TDS), and temperature through ESP32-based sensors integrated via cloud. The app also features real-time data sync, device control, and intuitive dashboards for users.

📌 [View the GitHub Repository](https://github.com/mulikruchi07/AquaWatch)

---

## 📱 Features

- ✅ User Authentication (Login/Register)
- 🌐 Wi-Fi-Based Device Linking with unique ID
- 📡 Real-Time Monitoring (Water Level, TDS, Temperature)
- 🎛️ Device Control (Switches for hardware)
- 👤 Profile Page (Support, Help, Password Update)
- 📲 Cross-platform (Android & iOS)

---

## 🛠 Tech Stack

| Layer        | Technology                        |
|--------------|------------------------------------|
| Frontend     | Flutter (Dart)                     |
| Backend      | Supabase (PostgreSQL, Auth, Realtime) |
| IoT Hardware | ESP32 + Sensors                    |
| Tools Used   | Git, GitHub, VS Code               |

---

## 📦 Installation

```bash
# Clone the repo
git clone https://github.com/mulikruchi07/AquaWatch.git

# Move into project directory
cd AquaWatch

# Get Flutter packages
flutter pub get

# Run on emulator or device
flutter run
