import sys
import threading
import uvicorn
import qrcode
from io import BytesIO
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, 
    QLabel, QPushButton, QTabWidget, QLineEdit, QFormLayout, 
    QListWidget, QMessageBox, QSystemTrayIcon, QMenu, QGroupBox,
    QScrollArea
)
from PyQt6.QtCore import Qt, QThread, pyqtSignal, QTimer
from PyQt6.QtGui import QIcon, QPixmap, QImage, QPainter, QColor, QFont

import config
from services.gateway_core import gateway_core
from services.pairing_manager import pairing_manager

# --- QSS Stylesheet matching Maat Mobile App Theme ---
MAAT_STYLESHEET = """
QMainWindow {
    background-color: #F5F2ED;
}
QWidget {
    font-family: 'Segoe UI', 'Inter', sans-serif;
    color: #2D2D2D;
    font-size: 14px;
}
QTabWidget::pane {
    border: 1px solid #D9D9D9;
    background: #FFFFFF;
    border-radius: 8px;
}
QTabBar::tab {
    background: #F0EDE8;
    color: #6B6B6B;
    padding: 8px 16px;
    margin-right: 2px;
    border-top-left-radius: 4px;
    border-top-right-radius: 4px;
}
QTabBar::tab:selected {
    background: #FFFFFF;
    color: #2D2D2D;
    border: 1px solid #D9D9D9;
    border-bottom: none;
    font-weight: bold;
}
QGroupBox {
    background: #FFFFFF;
    border: 1px solid #D9D9D9;
    border-radius: 8px;
    margin-top: 1ex;
    padding: 10px;
}
QGroupBox::title {
    subcontrol-origin: margin;
    subcontrol-position: top center;
    padding: 0 5px;
    color: #6B6B6B;
}
QPushButton {
    background-color: #FFFFFF;
    border: 1px solid #D9D9D9;
    border-radius: 6px;
    padding: 8px 16px;
    color: #2D2D2D;
}
QPushButton:hover {
    background-color: #F5F2ED;
}
QPushButton:pressed {
    background-color: #E8E8E8;
}
QPushButton#startBtn {
    background-color: #4CAF50;
    color: white;
    border: none;
}
QPushButton#stopBtn {
    background-color: #F44336;
    color: white;
    border: none;
}
QLineEdit {
    background-color: #F0EDE8;
    border: 1px solid #D9D9D9;
    border-radius: 4px;
    padding: 6px;
}
QListWidget {
    background-color: #F0EDE8;
    border: 1px solid #D9D9D9;
    border-radius: 4px;
}
QLabel#titleLabel {
    font-family: 'Georgia', 'Times New Roman', serif;
    font-size: 32px;
    font-style: italic;
    color: #2D2D2D;
}
"""

class ServerThread(QThread):
    finished_signal = pyqtSignal()
    
    def __init__(self, host, port, lmstudio_url):
        super().__init__()
        self.host = host
        self.port = port
        self.lmstudio_url = lmstudio_url
        self.server = None
        
    def run(self):
        import main
        uv_config = uvicorn.Config(
            main.app,
            host=self.host,
            port=self.port,
            reload=False,
            log_level="info"
        )
        self.server = uvicorn.Server(uv_config)
        self.server.run()
        self.finished_signal.emit()
        
    def stop(self):
        if self.server:
            self.server.should_exit = True

class GatewayDashboard(QMainWindow):
    def __init__(self, host, port, lmstudio_url):
        super().__init__()
        self.host = host
        self.port = port
        self.lmstudio_url = lmstudio_url
        self.server_thread = None
        
        self.setWindowTitle("Maat Gateway")
        self.setFixedSize(600, 500)
        self.setStyleSheet(MAAT_STYLESHEET)
        
        # Setup UI
        self._init_ui()
        self._init_tray()
        
        # Delay start to avoid immediate crash
        QTimer.singleShot(2000, self.start_server)
        
        # Status Polling Timer
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.update_status)
        self.timer.start(2000)
        
    def _init_ui(self):
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        
        # Header
        header_layout = QHBoxLayout()
        title_label = QLabel("Maat Gateway")
        title_label.setObjectName("titleLabel")
        header_layout.addWidget(title_label)
        header_layout.addStretch()
        main_layout.addLayout(header_layout)
        
        # Tabs
        self.tabs = QTabWidget()
        main_layout.addWidget(self.tabs)
        
        self._setup_dashboard_tab()
        self._setup_pairing_tab()
        self._setup_settings_tab()
        
    def _setup_dashboard_tab(self):
        tab = QWidget()
        layout = QVBoxLayout(tab)
        
        # Server Control
        server_group = QGroupBox("Server Control")
        server_layout = QHBoxLayout(server_group)
        
        self.server_status_label = QLabel("Server is OFF")
        self.server_status_label.setStyleSheet("font-weight: bold; color: #F44336;")
        
        self.start_btn = QPushButton("Start Server")
        self.start_btn.setObjectName("startBtn")
        self.start_btn.clicked.connect(self.start_server)
        
        self.stop_btn = QPushButton("Stop Server")
        self.stop_btn.setObjectName("stopBtn")
        self.stop_btn.clicked.connect(self.stop_server)
        self.stop_btn.setEnabled(False)
        
        server_layout.addWidget(self.server_status_label)
        server_layout.addStretch()
        server_layout.addWidget(self.start_btn)
        server_layout.addWidget(self.stop_btn)
        layout.addWidget(server_group)
        
        # LM Studio Status
        lm_group = QGroupBox("LM Studio Connection")
        lm_layout = QHBoxLayout(lm_group)
        self.lm_status_label = QLabel("Checking connection...")
        lm_layout.addWidget(self.lm_status_label)
        layout.addWidget(lm_group)
        
        layout.addStretch()
        self.tabs.addTab(tab, "Dashboard")
        
    def _setup_pairing_tab(self):
        tab = QWidget()
        layout = QVBoxLayout(tab)
        
        # QR Code
        qr_group = QGroupBox("Pair Device")
        qr_layout = QVBoxLayout(qr_group)
        self.qr_label = QLabel("Loading QR Code...")
        self.qr_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        qr_layout.addWidget(self.qr_label)
        layout.addWidget(qr_group)
        
        # Connected Devices
        dev_group = QGroupBox("Connected Devices")
        dev_layout = QVBoxLayout(dev_group)
        self.devices_list = QListWidget()
        dev_layout.addWidget(self.devices_list)
        
        refresh_dev_btn = QPushButton("Refresh Devices")
        refresh_dev_btn.clicked.connect(self.refresh_devices)
        dev_layout.addWidget(refresh_dev_btn)
        
        layout.addWidget(dev_group)
        self.tabs.addTab(tab, "Pairing & Devices")
        
    def _setup_settings_tab(self):
        tab = QWidget()
        layout = QVBoxLayout(tab)
        
        # API Keys
        api_group = QGroupBox("Cloud API Keys")
        form_layout = QFormLayout(api_group)
        
        self.openai_input = QLineEdit(config.OPENAI_API_KEY or "")
        self.openai_input.setEchoMode(QLineEdit.EchoMode.Password)
        form_layout.addRow("OpenAI:", self.openai_input)
        
        self.gemini_input = QLineEdit(config.GEMINI_API_KEY or "")
        self.gemini_input.setEchoMode(QLineEdit.EchoMode.Password)
        form_layout.addRow("Google Gemini:", self.gemini_input)
        
        self.anthropic_input = QLineEdit(config.ANTHROPIC_API_KEY or "")
        self.anthropic_input.setEchoMode(QLineEdit.EchoMode.Password)
        form_layout.addRow("Anthropic:", self.anthropic_input)
        
        save_btn = QPushButton("Save Keys")
        save_btn.clicked.connect(self.save_api_keys)
        form_layout.addRow("", save_btn)
        
        layout.addWidget(api_group)
        layout.addStretch()
        self.tabs.addTab(tab, "Settings")
        
    def _init_tray(self):
        # Create a simple icon programmatically if none exists
        pixmap = QPixmap(64, 64)
        pixmap.fill(QColor("#F5F2ED"))
        painter = QPainter(pixmap)
        painter.setBrush(QColor("#2D2D2D"))
        painter.drawRect(16, 16, 32, 32)
        painter.end()
        
        icon = QIcon(pixmap)
        self.setWindowIcon(icon)
        
        self.tray_icon = QSystemTrayIcon(icon, self)
        self.tray_icon.setToolTip("Maat Gateway")
        
        menu = QMenu()
        show_action = menu.addAction("Show Dashboard")
        show_action.triggered.connect(self.showNormal)
        
        quit_action = menu.addAction("Quit Gateway")
        quit_action.triggered.connect(self.quit_app)
        
        self.tray_icon.setContextMenu(menu)
        self.tray_icon.activated.connect(self.tray_activated)
        self.tray_icon.show()
        
    def tray_activated(self, reason):
        if reason == QSystemTrayIcon.ActivationReason.DoubleClick:
            self.showNormal()
            self.activateWindow()

    def start_server(self):
        if self.server_thread and self.server_thread.isRunning():
            return
            
        self.server_thread = ServerThread(self.host, self.port, self.lmstudio_url)
        self.server_thread.finished_signal.connect(self.on_server_stopped)
        self.server_thread.start()
        
        self.server_status_label.setText(f"Server is RUNNING on port {self.port}")
        self.server_status_label.setStyleSheet("font-weight: bold; color: #4CAF50;")
        self.start_btn.setEnabled(False)
        self.stop_btn.setEnabled(True)
        
        self.update_qr()
        self.refresh_devices()

    def stop_server(self):
        if self.server_thread:
            self.server_thread.stop()
            # It will emit finished_signal when completely stopped
            
    def on_server_stopped(self):
        self.server_status_label.setText("Server is OFF")
        self.server_status_label.setStyleSheet("font-weight: bold; color: #F44336;")
        self.start_btn.setEnabled(True)
        self.stop_btn.setEnabled(False)
        
    def update_status(self):
        if gateway_core.is_connected:
            self.lm_status_label.setText("🟢 Connected to LM Studio")
            self.lm_status_label.setStyleSheet("color: #4CAF50; font-weight: bold;")
        else:
            self.lm_status_label.setText("🔴 Disconnected / Not Reachable")
            self.lm_status_label.setStyleSheet("color: #F44336; font-weight: bold;")
            
    def update_qr(self):
        import json
        payload = pairing_manager.get_pairing_payload()
        qr_img = qrcode.make(json.dumps(payload))
        # Convert PIL image to QPixmap
        buf = BytesIO()
        qr_img.save(buf, "PNG")
        buf.seek(0)
        qimg = QImage.fromData(buf.read())
        pixmap = QPixmap.fromImage(qimg).scaled(200, 200, Qt.AspectRatioMode.KeepAspectRatio)
        self.qr_label.setPixmap(pixmap)
        
    def refresh_devices(self):
        self.devices_list.clear()
        # Device fetching requires async handling
        # To be implemented via asyncio injection or just fetching from a sync cache if available.
        self.devices_list.addItem("Device fetching requires async handling (placeholder)")

    def save_api_keys(self):
        openai = self.openai_input.text().strip()
        gemini = self.gemini_input.text().strip()
        anthropic = self.anthropic_input.text().strip()
        
        if openai:
            config.save_env_var("OPENAI_API_KEY", openai)
            config.OPENAI_API_KEY = openai
        if gemini:
            config.save_env_var("GEMINI_API_KEY", gemini)
            config.GEMINI_API_KEY = gemini
        if anthropic:
            config.save_env_var("ANTHROPIC_API_KEY", anthropic)
            config.ANTHROPIC_API_KEY = anthropic
            
        QMessageBox.information(self, "Success", "API Keys saved successfully to .env")
        
    def closeEvent(self, event):
        # Minimize to tray instead of closing
        event.ignore()
        self.hide()
        self.tray_icon.showMessage(
            "Maat Gateway",
            "Application minimized to tray. Server is still running.",
            QSystemTrayIcon.MessageIcon.Information,
            2000
        )
        
    def quit_app(self):
        self.stop_server()
        if self.server_thread:
            self.server_thread.wait(3000) # Wait up to 3 seconds for graceful shutdown
        QApplication.quit()
