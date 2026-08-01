# Maat - Local AI Mobile Client

[![Documentation](https://img.shields.io/badge/docs-website-blue.svg)](https://adarsh832.github.io/Matt/)

This is the mobile client for **Maat (Local LLM Mobile Companion)**, built with Flutter.
It acts as the frontend interface for chatting securely with your locally hosted Large Language Models (via LM Studio) from anywhere on your home network.

## Features

- **Local & Secure:** Pairs with your desktop gateway via QR code.
- **Multi-Chat History:** Conversations are automatically saved to the gateway's database. Access past chats, switch between conversations, and swipe-to-delete right from the chat drawer.
- **Live Streaming:** Responses stream in real-time, even if you navigate away during generation.
- **Personalities:** Switch between different AI personas (Coding Partner, Creative Writer, etc.).

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
