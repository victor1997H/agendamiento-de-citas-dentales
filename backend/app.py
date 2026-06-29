from flask import Flask, jsonify
from flask_cors import CORS

from routes.user_routes import user_bp

app = Flask(__name__)
CORS(app)

app.register_blueprint(user_bp)


@app.route("/")
def home():
    return jsonify({
        "success": True,
        "message": "API Dentis con JWT funcionando"
    })


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)