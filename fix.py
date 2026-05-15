import pymysql

conn = pymysql.connect(
    host="mysql-34ab522e-ecci-8a93.h.aivencloud.com",
    port=20082,
    user="avnadmin",
    password="AVNS_DNvTVCdgxKhnjmTjN0e",
    database="defaultdb",
    ssl={"ca": "C:/Users/Hewlett-Packard/Downloads/ca.pem"}
)
cursor = conn.cursor()

# Insertar Ana y Juan en tabla Agentes
cursor.execute("SELECT id_usuario FROM Usuarios WHERE correo='ana@helpdesk.com'")
ana = cursor.fetchone()
cursor.execute("SELECT id_usuario FROM Usuarios WHERE correo='juan@helpdesk.com'")
juan = cursor.fetchone()

cursor.execute("SELECT id_dep FROM Departamentos LIMIT 1")
dep = cursor.fetchone()

if ana:
    cursor.execute("INSERT IGNORE INTO Agentes (id_agente, id_dep, especialidad) VALUES (%s, %s, %s)",
        (ana[0], dep[0], 'Sistemas Operativos'))
if juan:
    cursor.execute("INSERT IGNORE INTO Agentes (id_agente, id_dep, especialidad) VALUES (%s, %s, %s)",
        (juan[0], dep[0], 'Redes y Conectividad'))

conn.commit()
cursor.close()
conn.close()
print("Agentes insertados OK")