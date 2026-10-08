import os
import sqlite3
from datetime import datetime

DB_PATH = os.path.join(os.path.dirname(__file__), "omnisense.db")

def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    with get_connection() as conn:
        cursor = conn.cursor()
        
        # User Memory Table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS user_memory (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                category TEXT NOT NULL DEFAULT 'fact',
                key_concept TEXT NOT NULL,
                content TEXT NOT NULL,
                location_context TEXT DEFAULT '',
                embedding_reference TEXT DEFAULT '',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Reminders Table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS reminders (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                category TEXT DEFAULT 'general',
                scheduled_time TEXT NOT NULL,
                recurrence TEXT DEFAULT 'none',
                is_active INTEGER DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # Expiries Table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS expiries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                item_name TEXT NOT NULL,
                category TEXT DEFAULT 'food',
                expiry_date TEXT NOT NULL,
                source TEXT DEFAULT 'ocr',
                confidence REAL DEFAULT 0.90,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # Observations Table (for Temporal Change Detection)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS observations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                objects_json TEXT NOT NULL,
                location TEXT DEFAULT 'table'
            )
        """)
        conn.commit()

# --- Memory Operations ---
def store_memory(key_concept: str, content: str, location_context: str = "", category: str = "fact", embedding_reference: str = ""):
    init_db()
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id FROM user_memory WHERE LOWER(key_concept) = LOWER(?)",
            (key_concept.strip(),)
        )
        row = cursor.fetchone()
        if row:
            cursor.execute("""
                UPDATE user_memory 
                SET content = ?, location_context = ?, category = ?, embedding_reference = ?, updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
            """, (content.strip(), location_context.strip(), category, embedding_reference, row["id"]))
            memory_id = row["id"]
        else:
            cursor.execute("""
                INSERT INTO user_memory (category, key_concept, content, location_context, embedding_reference)
                VALUES (?, ?, ?, ?, ?)
            """, (category, key_concept.strip(), content.strip(), location_context.strip(), embedding_reference))
            memory_id = cursor.lastrowid
        conn.commit()
        return memory_id

def query_memories(search_term: str = ""):
    init_db()
    with get_connection() as conn:
        cursor = conn.cursor()
        if search_term.strip():
            term = f"%{search_term.strip()}%"
            cursor.execute("""
                SELECT * FROM user_memory 
                WHERE key_concept LIKE ? OR content LIKE ? OR location_context LIKE ?
                ORDER BY updated_at DESC
            """, (term, term, term))
        else:
            cursor.execute("SELECT * FROM user_memory ORDER BY updated_at DESC LIMIT 50")
        return [dict(row) for row in cursor.fetchall()]

def delete_memory(memory_id: int):
    init_db()
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM user_memory WHERE id = ?", (memory_id,))
        conn.commit()

# --- Expiry Operations ---
def store_expiry(item_name: str, expiry_date: str, category: str = "food", confidence: float = 0.90):
    init_db()
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO expiries (item_name, category, expiry_date, confidence)
            VALUES (?, ?, ?, ?)
        """, (item_name, category, expiry_date, confidence))
        exp_id = cursor.lastrowid
        conn.commit()
        return exp_id

def query_expiries():
    init_db()
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM expiries ORDER BY expiry_date ASC")
        return [dict(row) for row in cursor.fetchall()]

# --- Observation Operations ---
def store_observation(objects_json: str, location: str = "table"):
    init_db()
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO observations (objects_json, location)
            VALUES (?, ?)
        """, (objects_json, location))
        obs_id = cursor.lastrowid
        conn.commit()
        return obs_id

def get_recent_observations(limit: int = 2):
    init_db()
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT * FROM observations ORDER BY id DESC LIMIT ?
        """, (limit,))
        return [dict(row) for row in cursor.fetchall()]

if __name__ == "__main__":
    init_db()
    print(f"OmniSense SQLite database initialized successfully at {DB_PATH}")
