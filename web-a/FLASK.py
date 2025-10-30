import os
import mysql.connector
from flask import Flask,request,jsonify,render_template
import time
from dotenv import load_dotenv

# --- 數據庫配置 ---
# 應用程式將從環境變數中讀取資料庫憑證。

load_dotenv()
DB_HOST = os.getenv("DB_HOST")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_DATABASE = os.getenv("DB_DATABASE")
app = Flask(__name__)
print(DB_HOST,DB_USER,DB_PASSWORD,DB_DATABASE)


def get_db_connection(max_retries=30, delay_seconds=5):
    """
    建立並返回一個 MySQL 連線，加入重試邏輯以處理 RDS 延遲啟動或暫時性網路錯誤。
    """
    conn = None
    for attempt in range(max_retries):
        try:
            conn = mysql.connector.connect(
                host=DB_HOST,
                user=DB_USER,
                password=DB_PASSWORD,
                database=DB_DATABASE,
                connection_timeout=5  # 設置單次連線超時
            )
            print(f"數據庫連線成功 (嘗試 {attempt + 1}/{max_retries})")
            return conn
        except mysql.connector.Error as err:
            if attempt < max_retries - 1:
                print(f"數據庫連線失敗 (嘗試 {attempt + 1}/{max_retries})：{err}。等待 {delay_seconds} 秒後重試...")
                time.sleep(delay_seconds)
            else:
                # 最後一次嘗試失敗
                print(f"數據庫連線最終失敗: {err}")
                return None
    return None

def create_user_table():
    conn = get_db_connection()
    if not conn:
        print("無法連接資料庫，無法創建表")
        return
    try:
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                nickname VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()
        print("users 表已創建或已存在")
    except mysql.connector.Error as err:
        print(f"創建表失敗: {err}")
    finally:
        cursor.close()
        conn.close()


@app.route("/")
def home():
    return render_template("home.html")  

@app.route("/index")
def index():
    return render_template("index.html") 

# --- 註冊 API 端點 (/register) ---
@app.route('/register', methods=['POST'])
def register_user():
    data = request.get_json()
    name = data.get('name')
    nickname = data.get('nickname')

    if not name or not nickname:
        return jsonify({"success": False, "message": "姓名和暱稱不能為空"}), 400

    conn = get_db_connection()
    if not conn:
        return jsonify({"success": False, "message": "數據庫服務不可用 (請檢查環境變數和 RDS 連線)"}), 503

    try:
        cursor = conn.cursor()
        # 使用 REPLACE INTO：如果 'name' 存在則更新，否則插入
        sql = "REPLACE INTO users (name, nickname) VALUES (%s, %s)"
        cursor.execute(sql, (name, nickname))
        conn.commit()
        
        return jsonify({"success": True, "message": f"使用者 '{name}' 註冊/更新成功"}), 200
    except mysql.connector.Error as err:
        print(f"註冊錯誤: {err}")
        return jsonify({"success": False, "message": f"註冊失敗: {err.msg}"}), 500
    finally:
        conn.close()

# --- 查詢 API 端點 (/search) ---
@app.route('/search', methods=['GET'])
def search_user():
    name = request.args.get('name')

    if not name:
        return jsonify({"success": False, "message": "請提供姓名進行查詢"}), 400

    conn = get_db_connection()
    if not conn:
        return jsonify({"success": False, "message": "數據庫服務不可用 (請檢查環境變數和 RDS 連線)"}), 503

    try:
        cursor = conn.cursor(dictionary=True) # 結果以字典形式返回
        sql = "SELECT nickname FROM users WHERE name = %s"
        cursor.execute(sql, (name,))
        result = cursor.fetchone()

        if result:
            nickname = result['nickname']
            return jsonify({"success": True, "nickname": nickname, "message": "查詢成功"}), 200
        else:
            return jsonify({"success": False, "message": f"找不到名為 '{name}' 的使用者"}), 404
    except mysql.connector.Error as err:
        print(f"查詢錯誤: {err}")
        return jsonify({"success": False, "message": f"查詢失敗: {err.msg}"}), 500
    finally:
        conn.close()

if __name__ == '__main__':
    create_user_table()
    app.run(host='0.0.0.0', port=5000)
