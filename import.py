import pymysql
import re

conn = pymysql.connect(
    host="mysql-34ab522e-ecci-8a93.h.aivencloud.com",
    port=20082,
    user="avnadmin",
    password="AVNS_DNvTVCdgxKhnjmTjN0e",
    database="defaultdb",
    ssl={"ca": "C:/Users/Hewlett-Packard/Downloads/ca.pem"}
)

cursor = conn.cursor()

with open("C:/Users/Hewlett-Packard/Downloads/helpdesk_db.sql", "r", encoding="utf-8") as f:
    sql = f.read()

# Limpiar sintaxis incompatible
sql = re.sub(r"USE\s+\w+\s*;", "", sql, flags=re.IGNORECASE)
sql = re.sub(r"CREATE\s+DATABASE[^;]+;", "", sql, flags=re.IGNORECASE)
sql = re.sub(r"CHARACTER SET\s+\w+", "", sql, flags=re.IGNORECASE)
sql = re.sub(r"COLLATE\s+\w+", "", sql, flags=re.IGNORECASE)
sql = re.sub(r"DEFAULT CHARSET=\w+", "", sql, flags=re.IGNORECASE)

errores = 0
for statement in sql.split(";"):
    stmt = statement.strip()
    if stmt:
        try:
            cursor.execute(stmt)
            conn.commit()
        except Exception as e:
            print(f"Error: {e}")
            errores += 1

cursor.close()
conn.close()
print(f"✅ Importación terminada con {errores} errores")