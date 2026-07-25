# Maat - Local AI Mobile Client

This is the mobile client for **Maat (Local LLM Mobile Companion)**, built with Flutter.
It acts as the frontend interface for chatting securely with your locally hosted Large Language Models (via LM Studio) from anywhere on your home network.

## Project Structure

- `lib/`
  - `screens/`: UI screens (Splash, Personality, QR Connection, Chat, Settings).
  - `theme/`: App-wide theming and color definitions (Material 3).
  - `widgets/`: Reusable UI components (ChatBubble, PersonalityCard, SettingsRow).

## Getting Started

1. Ensure the Python Gateway is running on your PC.
2. Run this Flutter app on your physical device or emulator.
3. Scan the QR code presented by the Gateway to pair your device.

For full architecture and backend setup instructions, please see the [main project README](../README.md).
