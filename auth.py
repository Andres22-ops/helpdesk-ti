from flask import Blueprint, render_template, request, session, redirect, url_for, flash
import bcrypt
import db

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        correo = request.form['correo']
        password = request.form['password']
        usuarios = db.query(
            "SELECT * FROM Usuarios WHERE correo = %s AND activo = 1",
            (correo,)
        )
        if usuarios:
            u = usuarios[0]
            if bcrypt.checkpw(password.encode(), u['password'].encode()):
                session['usuario'] = {
                    'id': u['id_usuario'],
                    'nombre': u['nombre'],
                    'rol': u['rol']
                }
                return redirect(url_for('index'))
        flash('Correo o contraseña incorrectos')
    return render_template('login.html')

@auth_bp.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('auth.login'))