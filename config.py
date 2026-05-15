import secrets

class Config:
    SECRET_KEY = secrets.token_hex(16)
    MYSQL_HOST = '127.0.0.1'
    MYSQL_PORT = 3306
    MYSQL_USER = 'root'
    MYSQL_PASSWORD = ''
    MYSQL_DATABASE = 'helpdesk_db'
    SESSION_TYPE = 'filesystem'