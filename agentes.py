from flask import Blueprint, render_template, request, session, redirect, url_for, flash
import db

agentes_bp = Blueprint('agentes', __name__)

def login_required(f):
    from functools import wraps
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'usuario' not in session:
            return redirect(url_for('auth.login'))
        if session['usuario']['rol'] not in ('Agente', 'Admin'):
            flash('No tienes permiso para acceder aquí')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return decorated

@agentes_bp.route('/')
@login_required
def dashboard():
    id_agente = session['usuario']['id']
    tickets = db.query(
        "SELECT t.*, e.nombre_estado, p.nivel_prio, c.nombre_cat, "
        "u.nombre AS cliente FROM Tickets t "
        "JOIN Estados e ON t.id_estado = e.id_estado "
        "JOIN Prioridades p ON t.id_prio = p.id_prio "
        "JOIN Categorias c ON t.id_cat = c.id_cat "
        "JOIN Usuarios u ON t.id_usuario = u.id_usuario "
        "WHERE t.id_agente = %s ORDER BY t.fecha_creacion DESC",
        (id_agente,)
    )
    total_activos = db.query(
    "SELECT COUNT(*) AS total FROM Tickets WHERE id_agente = %s AND id_estado != 3",
    (id_agente,)
    )
    return render_template('tickets/lista.html',
        tickets=tickets,
        usuario=session['usuario'],
        total_activos=total_activos[0]['total'])

@agentes_bp.route('/asignar/<int:id_ticket>', methods=['POST'])
@login_required
def asignar(id_ticket):
    id_agente = session['usuario']['id']
    conn = db.get_connection()
    cursor = conn.cursor()
    cursor.callproc('sp_asignar_agente', (id_ticket, id_agente, ''))
    conn.commit()
    cursor.close()
    conn.close()
    flash('Ticket asignado correctamente')
    return redirect(url_for('tickets.detalle', id_ticket=id_ticket))

@agentes_bp.route('/transferir/<int:id_ticket>', methods=['POST'])
@login_required
def transferir(id_ticket):
    id_agente_dest = request.form['id_agente_dest']
    motivo = request.form['motivo']
    conn = db.get_connection()
    cursor = conn.cursor()
    cursor.callproc('sp_transferir_ticket', (id_ticket, id_agente_dest, motivo, ''))
    conn.commit()
    cursor.close()
    conn.close()
    flash('Ticket transferido correctamente')
    return redirect(url_for('tickets.detalle', id_ticket=id_ticket))

@agentes_bp.route('/cerrar/<int:id_ticket>', methods=['POST'])
@login_required
def cerrar(id_ticket):
    conn = db.get_connection()
    cursor = conn.cursor()
    cursor.callproc('sp_cerrar_ticket', (id_ticket, ''))
    conn.commit()
    cursor.close()
    conn.close()
    flash('Ticket cerrado correctamente')
    return redirect(url_for('tickets.detalle', id_ticket=id_ticket))