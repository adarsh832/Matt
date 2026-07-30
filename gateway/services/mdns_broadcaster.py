"""Maat Gateway — mDNS Broadcaster Service."""

import socket
from zeroconf import ServiceInfo, Zeroconf
from config import GATEWAY_PORT, DEVICE_NAME, APP_VERSION

from utils.logger import get_logger

logger = get_logger("mdns")

class MDNSBroadcaster:
    def __init__(self):
        self.zeroconf = None
        self.info = None

    def _get_local_ip(self):
        """Try to get the local IP address."""
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            # doesn't even have to be reachable
            s.connect(('10.255.255.255', 1))
            IP = s.getsockname()[0]
        except Exception:
            IP = '127.0.0.1'
        finally:
            s.close()
        return IP

    def start(self):
        """Start the mDNS broadcast."""
        ip = self._get_local_ip()
        logger.info(f"Starting mDNS broadcast on IP: {ip}")
        
        # Use a custom service type specific to Maat
        service_type = "_maat._tcp.local."
        service_name = f"{DEVICE_NAME}._maat._tcp.local."
        
        # We can add properties to let the mobile app know the version or other info
        properties = {
            "version": APP_VERSION,
            "device": DEVICE_NAME
        }

        try:
            self.info = ServiceInfo(
                service_type,
                service_name,
                addresses=[socket.inet_aton(ip)],
                port=GATEWAY_PORT,
                properties=properties,
                server=f"{DEVICE_NAME}.local.",
            )
            self.zeroconf = Zeroconf()
            self.zeroconf.register_service(self.info)
            logger.info(f"Registered mDNS service: {service_name}")
        except Exception as e:
            logger.error(f"Failed to start mDNS broadcaster: {e}")

    def stop(self):
        """Stop the mDNS broadcast."""
        if self.zeroconf and self.info:
            logger.info("Stopping mDNS broadcast...")
            try:
                self.zeroconf.unregister_service(self.info)
                self.zeroconf.close()
                logger.info("mDNS service unregistered.")
            except Exception as e:
                logger.error(f"Error stopping mDNS broadcaster: {e}")

mdns_broadcaster = MDNSBroadcaster()
