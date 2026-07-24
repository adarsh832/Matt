# Local LLM Mobile Companion 📱🤖

[![Open Source Love svg1](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](https://github.com/ellerbrock/open-source-badges/)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)](https://www.python.org/)

**Local LLM Mobile Companion** is a free, open-source mobile application designed to untether you from your desk. It allows you to chat securely with your locally hosted Large Language Models (via LM Studio) from anywhere on your home network using your smartphone.

By utilizing a lightweight Python gateway on your PC and a fast Flutter mobile client, this project ensures that all inference runs on your own hardware. Your chats remain 100% private, with zero data sent to the cloud. Setup takes less than a minute via a simple QR code scan.

---

## ✨ Features (Version 0.1 MVP)

- **Zero Configuration:** Scan a QR code on your PC to instantly pair your mobile device.
- **100% Local & Private:** No cloud servers. All communication happens over your home Wi-Fi.
- **Real-time Streaming:** Watch the AI generate responses on your phone in real-time, just like on your desktop.
- **Model Switching:** Easily switch between the models you have installed in LM Studio.
- **Local Chat History:** All conversations are saved securely on your device.

---

## 🏗️ Architecture

The project is split into two main components:

1. **Python Gateway (`/gateway`)**: A lightweight FastAPI server that runs on your PC. It automatically detects LM Studio, exposes a secure REST API for the mobile app, handles streaming responses, and generates the pairing QR code.
2. **Mobile Application (`/mobile`)**: A Flutter application (Android/iOS) that acts as the client. It scans the QR code, pairs with the gateway, and provides a beautiful, native chat interface.

```text
Mobile App (Flutter)
     │
     │ HTTP/WebSocket
     ▼
Python Gateway (FastAPI)
     │
     │ Local API
     ▼
LM Studio 
     │
     ▼
Local LLM (Qwen, Llama, etc.)
```

---

## 🚀 Getting Started

### Prerequisites
- [LM Studio](https://lmstudio.ai/) installed and running on your PC with the "Local Server" started (default port 1234).
- Python 3.12+ installed.
- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.

### 1. Run the Python Gateway
```bash
cd gateway
# We recommend setting up a python virtual environment here
pip install -r requirements.txt
python main.py
```
*A QR code will be generated in your terminal.*

### 2. Run the Mobile App
```bash
cd mobile
flutter pub get
flutter run
```
*Scan the QR code displayed in your terminal using the app, and start chatting!*

---

## 🤝 Contributing

We are building this project in public and are actively looking for contributors! Whether you are a student looking for resume experience, a Flutter guru, or a Python developer, we want your help.

**How to contribute:**
1. Check the [Issues](#) tab for tasks labeled `good first issue` or `help wanted`.
2. Fork the repository and create a new branch for your feature.
3. Submit a Pull Request!

*(Note: We are currently focused on completing the Version 0.1 MVP).*

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
