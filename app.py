from flask import Flask, session, redirect, url_for
from config import Config
from flask_session import Session
import os

app = Flask(__name__)
app.config.from_object(Config)
Session(app)

# Blueprints
from auth import auth_bp
from tickets import tickets_bp
from agentes import agentes_bp
from admin import admin_bp

app.register_blueprint(auth_bp)
app.register_blueprint(tickets_bp, url_prefix='/tickets')
app.register_blueprint(agentes_bp, url_prefix='/agentes')
app.register_blueprint(admin_bp, url_prefix='/admin')

@app.route('/')
def index():
    if 'usuario' not in session:
        return redirect(url_for('auth.login'))
    rol = session['usuario']['rol']
    if rol == 'Admin':
        return redirect(url_for('admin.dashboard'))
    elif rol == 'Agente':
        return redirect(url_for('agentes.dashboard'))
    else:
        return redirect(url_for('tickets.dashboard'))

if __name__ == '__main__':
    os.makedirs('flask_session', exist_ok=True)
    app.run(debug=True)