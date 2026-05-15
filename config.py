import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret-key')
    SESSION_TYPE = 'filesystem'

    MYSQL_HOST     = os.environ.get('MYSQL_HOST', '127.0.0.1')
    MYSQL_PORT     = int(os.environ.get('MYSQL_PORT', 3306))
    MYSQL_USER     = os.environ.get('MYSQL_USER', 'root')
    MYSQL_PASSWORD = os.environ.get('MYSQL_PASSWORD', '')
    MYSQL_DATABASE = os.environ.get('MYSQL_DB', 'helpdesk_db')
    MYSQL_SSL_CA   = os.environ.get('MYSQL_SSL_CA', None)