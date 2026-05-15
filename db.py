import mysql.connector
from config import Config

def get_connection():
    args = dict(
        host=Config.MYSQL_HOST,
        port=Config.MYSQL_PORT,
        user=Config.MYSQL_USER,
        password=Config.MYSQL_PASSWORD,
        database=Config.MYSQL_DATABASE
    )
    if Config.MYSQL_SSL_CA:
        args['ssl_ca'] = Config.MYSQL_SSL_CA
        args['ssl_verify_cert'] = False

    return mysql.connector.connect(**args)

def query(sql, params=None, fetch=True):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(sql, params or ())
    if fetch:
        result = cursor.fetchall()
        cursor.close()
        conn.close()
        return result
    else:
        conn.commit()
        last_id = cursor.lastrowid
        cursor.close()
        conn.close()
        return last_id

def execute_procedure(nombre, params=()):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.callproc(nombre, params)
    conn.commit()
    results = []
    for r in cursor.stored_results():
        results.append(r.fetchall())
    cursor.close()
    conn.close()
    return results