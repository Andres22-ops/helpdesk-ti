from flask import Blueprint, render_template, request, session, redirect, url_for, flash
import db

tickets_bp = Blueprint('tickets', __name__)

def login_required(f):
    from functools import wraps
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'usuario' not in session:
            return redirect(url_for('auth.login'))
        return f(*args, **kwargs)
    return decorated

@tickets_bp.route('/')
@login_required
def dashboard():
    usuario = session['usuario']
    if usuario['rol'] == 'Cliente':
        tickets = db.query(
            "SELECT t.*, e.nombre_estado, p.nivel_prio, c.nombre_cat FROM Tickets t "
            "JOIN Estados e ON t.id_estado = e.id_estado "
            "JOIN Prioridades p ON t.id_prio = p.id_prio "
            "JOIN Categorias c ON t.id_cat = c.id_cat "
            "WHERE t.id_usuario = %s ORDER BY t.fecha_creacion DESC",
            (usuario['id'],)
        )
    else:
        tickets = db.query(
            "SELECT t.*, e.nombre_estado, p.nivel_prio, c.nombre_cat, "
            "u.nombre AS cliente FROM Tickets t "
            "JOIN Estados e ON t.id_estado = e.id_estado "
            "JOIN Prioridades p ON t.id_prio = p.id_prio "
            "JOIN Categorias c ON t.id_cat = c.id_cat "
            "JOIN Usuarios u ON t.id_usuario = u.id_usuario "
            "ORDER BY t.fecha_creacion DESC"
        )
    return render_template('tickets/lista.html', tickets=tickets, usuario=usuario)


@tickets_bp.route('/crear', methods=['GET', 'POST'])
@login_required
def crear():
    if request.method == 'POST':
        titulo      = request.form['titulo']
        descripcion = request.form['descripcion']
        id_prio     = request.form['id_prio']
        id_cat      = request.form['id_cat']
        id_usuario  = session['usuario']['id']
        db.query(
            "INSERT INTO Tickets (titulo, descripcion, id_usuario, id_prio, id_cat, id_estado) "
            "VALUES (%s, %s, %s, %s, %s, 1)",
            (titulo, descripcion, id_usuario, id_prio, id_cat),
            fetch=False
        )
        flash('Ticket creado exitosamente')
        return redirect(url_for('tickets.dashboard'))
    prioridades = db.query("SELECT * FROM Prioridades")
    categorias  = db.query("SELECT * FROM Categorias")
    return render_template('tickets/crear.html',
        prioridades=prioridades, categorias=categorias)


@tickets_bp.route('/<int:id_ticket>')
@login_required
def detalle(id_ticket):
    tickets = db.query(
        "SELECT t.*, e.nombre_estado, p.nivel_prio, c.nombre_cat, "
        "u.nombre AS cliente, ua.nombre AS agente_nombre FROM Tickets t "
        "JOIN Estados e ON t.id_estado = e.id_estado "
        "JOIN Prioridades p ON t.id_prio = p.id_prio "
        "JOIN Categorias c ON t.id_cat = c.id_cat "
        "JOIN Usuarios u ON t.id_usuario = u.id_usuario "
        "LEFT JOIN Usuarios ua ON t.id_agente = ua.id_usuario "
        "WHERE t.id_ticket = %s", (id_ticket,)
    )
    if not tickets:
        flash('Ticket no encontrado')
        return redirect(url_for('tickets.dashboard'))

    historial = db.query(
        "SELECT h.*, uo.nombre AS origen, ud.nombre AS destino "
        "FROM Historial_Transferencias h "
        "LEFT JOIN Usuarios uo ON h.id_agente_origen = uo.id_usuario "
        "LEFT JOIN Usuarios ud ON h.id_agente_dest = ud.id_usuario "
        "WHERE h.id_ticket = %s ORDER BY h.fecha_trans DESC", (id_ticket,)
    )
    comentarios = db.query(
        "SELECT c.*, u.nombre AS autor, u.rol FROM Comentarios c "
        "JOIN Usuarios u ON c.id_usuario = u.id_usuario "
        "WHERE c.id_ticket = %s ORDER BY c.fecha ASC", (id_ticket,)
    )
    agentes = db.query(
        "SELECT id_usuario AS id_agente, nombre FROM Usuarios WHERE rol = 'Agente'"
    )
    return render_template('tickets/detalle.html',
        ticket=tickets[0], historial=historial,
        comentarios=comentarios, agentes=agentes,
        usuario=session['usuario'])


@tickets_bp.route('/<int:id_ticket>/comentar', methods=['POST'])
@login_required
def comentar(id_ticket):
    comentario = request.form.get('comentario', '').strip()
    if not comentario:
        flash('El comentario no puede estar vacío')
        return redirect(url_for('tickets.detalle', id_ticket=id_ticket))
    db.query(
        "INSERT INTO Comentarios (id_ticket, id_usuario, comentario) "
        "VALUES (%s, %s, %s)",
        (id_ticket, session['usuario']['id'], comentario),
        fetch=False
    )
    flash('Comentario agregado')
    return redirect(url_for('tickets.detalle', id_ticket=id_ticket))