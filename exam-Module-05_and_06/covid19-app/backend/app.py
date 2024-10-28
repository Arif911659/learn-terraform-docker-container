from flask import Flask, jsonify
import requests

app = Flask(__name__)

@app.route('/api/covid-data', methods=['GET'])
def get_covid_data():
    try:
        response = requests.get('https://api.covid19api.com/summary')
        data = response.json()
        return jsonify(data), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)