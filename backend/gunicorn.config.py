# gunicorn.config.py
import os

bind = f"0.0.0.0:{os.getenv('PORT', '5000')}"
workers = 2
worker_class = "sync"
worker_connections = 1000
timeout = 120
keepalive = 5
errorlog = "-"
accesslog = "-"
loglevel = "info"
preload_app = True
