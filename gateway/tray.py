import threading
import webbrowser
import pystray
from pystray import MenuItem as item
from PIL import Image, ImageDraw

from config import GATEWAY_HOST, GATEWAY_PORT
from services.gateway_core import gateway_core
from services.pairing_manager import pairing_manager

def create_default_icon():
    # Create a simple 64x64 icon using PIL
    image = Image.new('RGB', (64, 64), color=(30, 30, 30))
    dc = ImageDraw.Draw(image)
    dc.rectangle(
        (16, 16, 48, 48),
        fill=(0, 120, 215)
    )
    return image

def get_status_text(icon: pystray.Icon) -> str:
    if gateway_core.is_connected:
        return "LM Studio: Connected"
    return "LM Studio: Not Reachable"

def show_qr(icon: pystray.Icon, item: pystray.MenuItem):
    payload = pairing_manager.get_pairing_payload()
    url = f"{payload['server']}/pair/qr"
    webbrowser.open(url)

def on_quit_callback(icon: pystray.Icon, item: pystray.MenuItem, quit_event: threading.Event):
    quit_event.set()
    icon.stop()

def setup_tray(quit_event: threading.Event) -> pystray.Icon:
    icon_image = create_default_icon()
    
    menu = pystray.Menu(
        item(lambda text: get_status_text(text), None, enabled=False),
        pystray.Menu.SEPARATOR,
        item('Pairing QR', show_qr),
        pystray.Menu.SEPARATOR,
        item('Quit', lambda icon, menu_item: on_quit_callback(icon, menu_item, quit_event))
    )
    
    icon = pystray.Icon("maat_gateway", icon_image, "Maat Gateway", menu)
    return icon
