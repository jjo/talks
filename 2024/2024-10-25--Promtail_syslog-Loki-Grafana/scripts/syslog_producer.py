#!/usr/bin/env python3
import socket
import time
import random
from datetime import datetime
import argparse
import os

class SyslogProducer:
    # Syslog facilities
    FACILITIES = {
        'kern': 0,
        'user': 1,
        'mail': 2,
        'daemon': 3,
        'auth': 4,
        'syslog': 5,
        'local0': 16,
        'local1': 17,
        'local2': 18
    }

    # Syslog severities
    SEVERITIES = {
        'emerg': 0,
        'alert': 1,
        'crit': 2,
        'err': 3,
        'warning': 4,
        'notice': 5,
        'info': 6,
        'debug': 7
    }

    def __init__(self, host='localhost', port=1514):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.target = (host, port)
        self.hostname = socket.gethostname()
        self.pid = os.getpid()

    def generate_message(self):
        """Generate a random syslog message"""
        messages = [
            "User authentication successful",
            "Failed login attempt from IP 192.168.1.100",
            "System CPU usage above 80%",
            "Database backup completed successfully",
            "Network interface eth0 down",
            "Disk space usage warning: /dev/sda1 90% full",
            "Service restart initiated",
            "Memory usage exceeded threshold",
            "New user account created",
            "Security update available"
        ]
        
        facility = random.choice(list(self.FACILITIES.keys()))
        severity = random.choice(list(self.SEVERITIES.keys()))
        message = random.choice(messages)
        
        return facility, severity, message

    def send_message(self, facility, severity, message):
        """Send a RFC5424 formatted syslog message"""
        # Calculate priority value (PRI)
        priority = self.FACILITIES[facility] * 8 + self.SEVERITIES[severity]
        
        # Get timestamp in RFC5424 format
        timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%fZ')
        
        # Format version and message
        version = "1"  # RFC5424 version is 1
        proc_id = str(self.pid)
        msg_id = "-"  # Optional
        structured_data = "-"  # No structured data
        app_name = "test_app"
        
        # Format RFC5424 message
        # <PRI>VERSION TIMESTAMP HOSTNAME APP-NAME PROCID MSGID STRUCTURED-DATA MSG
        syslog_message = f'<{priority}>{version} {timestamp} {self.hostname} {app_name} {proc_id} {msg_id} {structured_data} {message}'
        
        # Send message
        self.sock.sendto(syslog_message.encode(), self.target)
        print(f"Sent: {syslog_message}")

    def run(self, interval=1.0, count=None):
        """Run the producer"""
        messages_sent = 0
        try:
            while True:
                facility, severity, message = self.generate_message()
                self.send_message(facility, severity, message)
                messages_sent += 1
                
                if count and messages_sent >= count:
                    break
                    
                time.sleep(interval)
                
        except KeyboardInterrupt:
            print("\nStopping syslog producer")
        finally:
            self.sock.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Generate RFC5424 syslog messages')
    parser.add_argument('--host', default='localhost', help='Syslog server host')
    parser.add_argument('--port', type=int, default=1514, help='Syslog server port')
    parser.add_argument('--interval', type=float, default=1.0, help='Interval between messages in seconds')
    parser.add_argument('--count', type=int, help='Number of messages to send (default: infinite)')
    
    args = parser.parse_args()
    
    producer = SyslogProducer(args.host, args.port)
    producer.run(args.interval, args.count)
