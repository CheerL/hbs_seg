from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy
import json
from flask_cors import CORS
from run import run
import multiprocessing


app = Flask(__name__)
CORS(app)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///data.db'  # SQLite3 database
db = SQLAlchemy(app)

# Define a model for your table
class MyTable(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), default='')
    config = db.Column(db.String(1000), default='{}')
    result = db.Column(db.String(255), default='')


@app.route('/api/data', methods=['GET'])
def get_data():
    try:
        name = request.args.get('name')
        id_ = request.args.get('id')

        if name is None and id_ is None:
            data = MyTable.query.all()
            serialized_data = [
                {
                    'id': entry.id,
                    'name': entry.name, 
                    'config': json.loads(entry.config),
                    'result': entry.result
                } for entry in data
            ]
        else:
            if name is not None:
                entry = MyTable.query.filter_by(name=name).first()
            elif id_ is not None:
                entry = MyTable.query.filter_by(id=id_).first()
            else:
                return jsonify({'error': 'Missing name or id parameter'}), 400

            if entry:
                serialized_data = {
                    'id': entry.id,
                    'name': entry.name,
                    'config': json.loads(entry.config),
                    'result': entry.result
                }
            else:
                return jsonify({'message': 'Data not found'}), 404
        #print(serialized_data)
        return jsonify(serialized_data)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/data', methods=['POST'])
def add_data():
    try:
        # 从请求中获取数据
        data = request.get_json()
        
        if isinstance(data, dict):
            data = [data]
        
        # 创建 MyTable 对象并添加到数据库
        for each in data:
            if 'id' in each:
                entry = MyTable.query.filter_by(id=each['id']).first()
                if entry:
                    entry.name = each.get('name', entry.name)
                    entry.config = json.dumps(each.get('config', json.loads(entry.config)))
                    entry.result = each.get('result', entry.result)
                else:
                    entry = MyTable(
                        id=each['id'],
                        name=each.get('name', ''),
                        config=json.dumps(each['config']),
                        result=each.get('result', '')
                    )
                    db.session.add(entry)

            else:
                entry = MyTable(
                    name=each.get('name', ''),
                    config=json.dumps(each['config']),
                    result=each.get('result', '')
                )
                db.session.add(entry)
        db.session.commit()

        return jsonify({'message': 'Data added successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# 更新记录（根据name或id）
@app.route('/api/data', methods=['PUT'])
def update_data():
    try:
        name = request.args.get('name')
        id_ = request.args.get('id')

        if name is not None:
            entry = MyTable.query.filter_by(name=name).first()
        elif id_ is not None:
            entry = MyTable.query.filter_by(id=id_).first()
        else:
            return jsonify({'error': 'Missing name or id parameter'}), 400

        if entry:
            data = request.get_json()

            # 更新记录的字段
            entry.name = data.get('name', entry.name)
            entry.config = json.dumps(data.get('config', json.loads(entry.config)))
            entry.result = data.get('result', entry.result)

            # 提交更新到数据库
            db.session.commit()

            return jsonify({'message': 'Data updated successfully'})
        else:
            return jsonify({'message': 'Data not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# 删除记录（根据name或id）
@app.route('/api/data', methods=['DELETE'])
def delete_data():
    try:
        name = request.args.get('name')
        id_ = request.args.get('id')

        if name is not None:
            entry = MyTable.query.filter_by(name=name).first()
        elif id_ is not None:
            entry = MyTable.query.filter_by(id=id_).first()
        else:
            return jsonify({'error': 'Missing name or id parameter'}), 400

        if entry:
            db.session.delete(entry)
            db.session.commit()

            return jsonify({'message': 'Data deleted successfully'})
        else:
            return jsonify({'message': 'Data not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@app.route('/api/data/run', methods=['POST'])
def run_data():
    try:
        data = request.get_json()

        entry = MyTable.query.filter_by(id=data['id']).first()
        if entry:
            with multiprocessing.Pool() as pool:
                task = pool.apply_async(run, (data['config'], data['name'],))
                pool.close()
                pool.join()
                result = task.get()
            #result = run(data['config'], data['name'])
            entry.result = result
            db.session.commit()
            return jsonify({'result': result})
        else:
            return jsonify({'message': 'Data not found'}), 404

    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        app.run(debug=True, host='0.0.0.0', port=8035)
