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
        "SELECT COUNT(*) AS total FROM Tickets WHERE id_agente = %s AND id_estado != "
        "(SELECT id_estado FROM Estados WHERE nombre_estado = 'Cerrado' LIMIT 1)",
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
    try:
        db.query(
            "UPDATE Tickets SET id_agente = %s, id_estado = "
            "(SELECT id_estado FROM Estados WHERE nombre_estado = 'Asignado' LIMIT 1) "
            "WHERE id_ticket = %s",
            (id_agente, id_ticket), fetch=False
        )
        flash('Ticket asignado correctamente')
    except Exception as e:
        flash(f'Error al asignar: {str(e)}')
    return redirect(url_for('tickets.detalle', id_ticket=id_ticket))


@agentes_bp.route('/transferir/<int:id_ticket>', methods=['POST'])
@login_required
def transferir(id_ticket):
    id_agente_dest = request.form['id_agente_dest']
    motivo         = request.form.get('motivo', '')
    id_agente_orig = session['usuario']['id']

    # Si quien transfiere es Admin no está en Agentes, se pone NULL
    es_agente = db.query(
        "SELECT COUNT(*) AS total FROM Agentes WHERE id_agente = %s",
        (id_agente_orig,)
    )
    origen = id_agente_orig if es_agente[0]['total'] > 0 else None

    try:
        db.query(
            "INSERT INTO Historial_Transferencias "
            "(id_ticket, id_agente_origen, id_agente_dest, motivo, fecha_trans) "
            "VALUES (%s, %s, %s, %s, NOW())",
            (id_ticket, origen, id_agente_dest, motivo), fetch=False
        )
        db.query(
            "UPDATE Tickets SET id_agente = %s, id_estado = "
            "(SELECT id_estado FROM Estados WHERE nombre_estado = 'Asignado' LIMIT 1) "
            "WHERE id_ticket = %s",
            (id_agente_dest, id_ticket), fetch=False
        )
        flash('Ticket transferido correctamente')
    except Exception as e:
        flash(f'Error al transferir: {str(e)}')
    return redirect(url_for('tickets.detalle', id_ticket=id_ticket))


@agentes_bp.route('/cerrar/<int:id_ticket>', methods=['POST'])
@login_required
def cerrar(id_ticket):
    try:
        db.query(
            "UPDATE Tickets SET id_estado = "
            "(SELECT id_estado FROM Estados WHERE nombre_estado = 'Cerrado' LIMIT 1) "
            "WHERE id_ticket = %s",
            (id_ticket,), fetch=False
        )
        flash('Ticket cerrado correctamente')
    except Exception as e:
        flash(f'Error al cerrar: {str(e)}')
    return redirect(url_for('tickets.detalle', id_ticket=id_ticket))