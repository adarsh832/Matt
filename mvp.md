## Local LLM Mobile Companion - MVP (Version 0.1)

## Overview

The goal of this project is to create a free, open-source mobile application that allows users to chat with their locally running LLM from anywhere on their home network.

Unlike cloud AI services, all inference runs on the user's own computer using LM Studio. The mobile application acts only as a client, while a lightweight Python gateway communicates with LM Studio.

The first version focuses only on providing a smooth chat experience. Features such as MCP, tool calling, browser automation, plugins, and remote cloud access will be introduced in future updates.

## Objectives

The MVP should allow a user to:

- Install and run a lightweight Python gateway.

- Automatically detect LM Studio.

- Scan a QR code from the mobile application.

- Pair the mobile device with the gateway.

- Chat with the local LLM.

- View streaming responses.

- Switch between installed models.

The setup should take less than five minutes for a new user.

## Out of Scope (Future Versions)

The following features are intentionally excluded from Version 0.1:

- MCP integration

- Tool calling

- Browser automation

- File uploads

- Voice chat

- Vision models

- Plugin marketplace

- Cloud synchronization

- Remote access (Cloudflare Tunnel/Tailscale)

- Multiple user accounts

- Authentication providers

These will be implemented in later releases.


## System Architecture

Mobile App

│

│ HTTP/WebSocket

Python Gateway

│

LM Studio Local API

│

Local LLM

The mobile application never communicates directly with LM Studio.

All communication passes through the Python gateway.

## Components

## 1. Mobile Application

## Responsibilities:

- Pair with gateway

- Display conversations

- Send messages

- Receive streamed responses

- Display available models

- Switch models

- Manage chat history

The mobile app should remain lightweight and contain no AI logic.

## 2. Python Gateway

## Responsibilities:

- Detect LM Studio

- Expose REST API

- Handle chat requests

- Handle streaming

- Generate QR code

- Manage pairing

- Store chat history


- Retrieve available models

The gateway is responsible for all communication with LM Studio.

## 3. LM Studio

Responsibilities:

- Run local LLM

- Generate responses

- Provide model list

- Expose local API

No modifications are required.

## First Launch Experience

The first-time setup should be as simple as possible.

## User runs:

yourapp

The gateway should automatically:

- Start the server

- Detect LM Studio

- Verify API connectivity

- Retrieve installed models

- Generate a pairing QR code

- Wait for mobile connection

Example console output:

Local AI Server

## Status:

- Gateway Running

- LM Studio Connected

- Models Found

Waiting for mobile device...


No manual IP or port entry should be required.

## QR Pairing

The gateway generates a QR code containing:

```
{
"server": "http://192.168.1.15:8080",
"device_name": "My Laptop",
"pairing_token": "random-token"
}
```

The mobile application scans the QR code.

It automatically connects to the gateway.

The user does not need to enter:

- IP address

- Port

- API URL

## Pairing Flow

- 1. Gateway starts.

- 2. QR code is generated.

- 3. Mobile scans QR.

- 4. Mobile sends pairing request.

- 5. Gateway asks for approval.

- 6. User accepts.

- 7. Device is saved.

- 8. Chat is enabled.

Future launches should reconnect automatically.

## Backend API

## Health Check

GET


/health

Response

```
{
"status": "ok",
"lmstudio": true
}
```

## Models

GET

/models

Response

```
[
{
"id": "qwen3",
"name": "Qwen3"
},
{
"id": "granite",
"name": "Granite 4"
}
]
```

## Pair Device

POST

/pair

Request

```
{
"device_name": "Pixel 9",
```


```
"pairing_token": "xxxxx"
}
```

Response

```
{
"success": true
}
```

## Chat

## POST

/chat

## Request

```
{
"conversation_id": "123",
"model": "qwen3",
"message": "Explain quantum computing simply."
}
```

Response (streamed)

```
Quantum computing is...
```

## Chat Features

Version 0.1 includes:

- Create conversation

- Continue conversation

- Rename conversation

- Delete conversation

- Streaming responses

- Markdown rendering

- Code blocks

- Copy message

- Retry response


## Mobile UI

## Home

- Conversation list

- New Chat button

- Settings

## Chat Screen

- Message history

- Streaming assistant response

- Text input

- Send button

- Stop generation button

- Model selector

## Settings

- Connected device

- Current model

- Connection status

- Disconnect device

## Gateway Dashboard

The gateway should provide a simple local dashboard (terminal initially, GUI later).

## Example:

==============================

Local AI Server

==============================

Status

- Gateway Running

- LM Studio Connected

Current Model Qwen3


```
Connected Devices
1
Address
192.168.1.15:8080
Scan QR Code
==============================
```

## Suggested Technology Stack

## Mobile

- Flutter

- Material Design

## Backend

- Python 3.12+

- FastAPI

- Uvicorn

- HTTPX

- SQLite

- qrcode (QR generation)

## Local AI

- LM Studio

## Suggested Project Structure

```
local-llm-mobile/
mobile/
Flutter application
gateway/
main.py
routes/
services/
database/
utils/
```


shared/ docs/ README.md

## Success Criteria

The MVP will be considered complete when:

- A user can install and start the gateway in one command.

- The gateway automatically detects LM Studio.

- A QR code is generated for pairing.

- The mobile app pairs without manual configuration.

- The user can select a model.

- The user can send and receive streamed messages.

- Chat history is preserved locally.

- The entire setup process takes less than five minutes.

## Roadmap After Version 0.1

## Version 0.2

- Better UI polish

- Search conversations

- Export chat

- Desktop tray application

## Version 0.3

- MCP integration

- Tool calling

- Integration management

## Version 0.4

- Browser automation

- File uploads

- Voice chat

## Version 1.0

- Plugin marketplace

- Remote access (Cloudflare Tunnel/Tailscale)

- One-click integration installation

- Full self-hosted AI workspace
