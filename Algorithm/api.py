# Importing Libraries
from flask import Flask, request, jsonify
from pymongo import MongoClient
from flask_cors import CORS
from werkzeug.serving import WSGIRequestHandler

# Creating the application
app = Flask(__name__)
CORS(app)

# Information of the mongoDB database
client = MongoClient('mongodb://localhost:27017/') 
db = client['SoilTemp'] 
collection = db['test']

@app.route('/store', methods=['POST'])
#Function to store data
def store():

    data = request.get_json()

    collection.insert_one(data)

    return jsonify({
        "message": "Success"
    })

@app.route('/obtain', methods=['GET'])
#Function to get data
def obtain():

    documents = collection.find()

    

    return documents

# Start app
if __name__ == '__main__':
    WSGIRequestHandler.protocol_version = "HTTP/1.1"
    app.run(debug=False, use_reloader=False)