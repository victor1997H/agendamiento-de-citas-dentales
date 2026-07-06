import os

from flask import Flask, jsonify
from flask_cors import CORS

from routes.user_routes import user_bp
from routes.cita_routes import cita_bp

app = Flask(__name__)
CORS(app)

# blueprints
app.register_blueprint(user_bp)
app.register_blueprint(cita_bp)

@app.route("/")
def home():
    return jsonify({
        "success": True,
        "message": "API Dentis funcionando"
    })

if __name__ == "__main__":
    debug = os.getenv("FLASK_DEBUG", "false").lower() == "true"
    port = int(os.getenv("PORT", "5000"))
    app.run(host="0.0.0.0", port=port, debug=debug)
