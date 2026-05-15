from flask import Blueprint, render_template, request, session, redirect, url_for, flash
import db
import bcrypt

admin_bp = Blueprint('admin', __name__)

def admin_required(f):
    from functools import wraps
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'usuario' not in session:
            return redirect(url_for('auth.login'))
        if session['usuario']['rol'] != 'Admin':
            flash('Solo administradores pueden acceder aquí')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return decorated

@admin_bp.route('/')
@admin_required
def dashboard():
    total_tickets = db.query("SELECT COUNT(*) AS total FROM Tickets")[0]['total']
    tickets_abiertos = db.query(
        "SELECT COUNT(*) AS total FROM Tickets t "
        "JOIN Estados e ON t.id_estado = e.id_estado "
        "WHERE e.nombre_estado = 'Abierto'"
    )[0]['total']
    tickets_cerrados = db.query(
        "SELECT COUNT(*) AS total FROM Tickets t "
        "JOIN Estados e ON t.id_estado = e.id_estado "
        "WHERE e.nombre_estado = 'Cerrado'"
    )[0]['total']
    agentes = db.query(
        "SELECT u.nombre, u.correo, d.nombre_dep, a.especialidad "
        "FROM Agentes a "
        "JOIN Usuarios u ON a.id_agente = u.id_usuario "
        "JOIN Departamentos d ON a.id_dep = d.id_dep"
    )
    return render_template('admin/dashboard.html',
        total_tickets=total_tickets,
        tickets_abiertos=tickets_abiertos,
        tickets_cerrados=tickets_cerrados,
        agentes=agentes,
        usuario=session['usuario'])

@admin_bp.route('/usuarios')
@admin_required
def usuarios():
    usuarios = db.query(
        "SELECT id_usuario, nombre, correo, rol, activo FROM Usuarios"
    )
    return render_template('admin/usuarios.html',
        usuarios=usuarios, usuario=session['usuario'])

@admin_bp.route('/usuarios/crear', methods=['GET', 'POST'])
@admin_required
def crear_usuario():
    if request.method == 'POST':
        nombre = request.form['nombre']
        correo = request.form['correo']
        password = request.form['password']
        rol = request.form['rol']
        hash_pw = bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()
        try:
            db.query(
                "INSERT INTO Usuarios (nombre, correo, password, rol) "
                "VALUES (%s, %s, %s, %s)",
                (nombre, correo, hash_pw, rol), fetch=False
            )
            flash('Usuario creado exitosamente')
            return redirect(url_for('admin.usuarios'))
        except Exception as e:
            flash(f'Error: {e}')
    departamentos = db.query("SELECT * FROM Departamentos")
    return render_template('admin/crear_usuario.html',
        departamentos=departamentos, usuario=session['usuario'])

@admin_bp.route('/tickets')
@admin_required
def tickets():
    tickets = db.query(
        "SELECT t.*, e.nombre_estado, p.nivel_prio, c.nombre_cat, "
        "u.nombre AS cliente, ua.nombre AS agente_nombre FROM Tickets t "
        "JOIN Estados e ON t.id_estado = e.id_estado "
        "JOIN Prioridades p ON t.id_prio = p.id_prio "
        "JOIN Categorias c ON t.id_cat = c.id_cat "
        "JOIN Usuarios u ON t.id_usuario = u.id_usuario "
        "LEFT JOIN Agentes a ON t.id_agente = a.id_agente "
        "LEFT JOIN Usuarios ua ON a.id_agente = ua.id_usuario "
        "ORDER BY t.fecha_creacion DESC"
    )
    return render_template('admin/tickets.html',
        tickets=tickets, usuario=session['usuario'])