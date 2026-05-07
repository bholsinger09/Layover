#!/usr/bin/env python3
"""
Generate translations.db SQLite database for Language Exchange feature
"""
import sqlite3
import os

# All translations from the original implementation
translations = {
    "en-es": {
        "hello": "hola", "goodbye": "adiós", "please": "por favor", "thank you": "gracias",
        "yes": "sí", "no": "no", "good": "bueno", "bad": "malo", "big": "grande",
        "small": "pequeño", "hot": "caliente", "cold": "frío", "new": "nuevo",
        "old": "viejo", "young": "joven", "good morning": "buenos días",
        "good night": "buenas noches", "how are you": "cómo estás", "my name is": "me llamo",
        "nice to meet you": "mucho gusto", "excuse me": "perdón", "i'm sorry": "lo siento",
        "help": "ayuda", "water": "agua", "food": "comida", "house": "casa",
        "car": "coche", "book": "libro", "table": "mesa", "chair": "silla",
        "window": "ventana", "door": "puerta", "phone": "teléfono", "computer": "ordenador",
        "friend": "amigo", "family": "familia", "mother": "madre", "father": "padre",
        "sister": "hermana", "brother": "hermano", "son": "hijo", "daughter": "hija",
        "grandmother": "abuela", "grandfather": "abuelo", "work": "trabajo", "school": "escuela",
        "home": "hogar", "city": "ciudad", "country": "país", "world": "mundo",
        "day": "día", "night": "noche", "week": "semana", "month": "mes",
        "year": "año", "time": "tiempo", "hour": "hora", "minute": "minuto",
        "today": "hoy", "tomorrow": "mañana", "yesterday": "ayer", "now": "ahora",
        "monday": "lunes", "tuesday": "martes", "wednesday": "miércoles",
        "thursday": "jueves", "friday": "viernes", "saturday": "sábado", "sunday": "domingo",
        "one": "uno", "two": "dos", "three": "tres", "four": "cuatro",
        "five": "cinco", "six": "seis", "seven": "siete", "eight": "ocho",
        "nine": "nueve", "ten": "diez", "hundred": "cien", "thousand": "mil",
        "red": "rojo", "blue": "azul", "green": "verde", "yellow": "amarillo",
        "black": "negro", "white": "blanco", "happy": "feliz", "sad": "triste",
        "angry": "enojado", "tired": "cansado", "hungry": "hambriento", "thirsty": "sediento",
        "beautiful": "hermoso", "ugly": "feo", "fast": "rápido", "slow": "lento",
        "easy": "fácil", "difficult": "difícil", "important": "importante",
        "interesting": "interesante", "love": "amor", "money": "dinero",
        "street": "calle", "restaurant": "restaurante", "hotel": "hotel",
        "beach": "playa", "mountain": "montaña", "river": "río", "sea": "mar",
        "sun": "sol", "moon": "luna", "star": "estrella", "sky": "cielo",
        "rain": "lluvia", "snow": "nieve", "wind": "viento", "tree": "árbol",
        "flower": "flor", "grass": "hierba", "dog": "perro", "cat": "gato",
        "bird": "pájaro", "fish": "pez", "head": "cabeza", "eyes": "ojos",
        "ears": "oídos", "nose": "nariz", "mouth": "boca", "hand": "mano",
        "foot": "pie", "heart": "corazón", "me": "yo", "you": "tú",
        "he": "él", "she": "ella", "we": "nosotros", "they": "ellos",
        "this": "esto", "that": "eso", "here": "aquí", "there": "allí",
        "what": "qué", "where": "dónde", "when": "cuándo", "why": "por qué",
        "how": "cómo", "who": "quién", "which": "cuál", "test": "prueba",
        "message": "mensaje", "chat": "charla", "speak": "hablar", "listen": "escuchar",
        "read": "leer", "write": "escribir", "learn": "aprender", "teach": "enseñar",
        "understand": "entender", "know": "saber", "think": "pensar", "want": "querer",
        "need": "necesitar", "like": "gustar", "have": "tener", "be": "ser",
        "do": "hacer", "go": "ir", "come": "venir", "see": "ver",
        "eat": "comer", "drink": "beber", "sleep": "dormir", "wake": "despertar"
    },
    "es-en": {
        "hola": "hello", "adiós": "goodbye", "por favor": "please", "gracias": "thank you",
        "sí": "yes", "no": "no", "bueno": "good", "malo": "bad", "grande": "big",
        "pequeño": "small", "caliente": "hot", "frío": "cold", "nuevo": "new",
        "viejo": "old", "joven": "young", "buenos días": "good morning",
        "buenas noches": "good night", "cómo estás": "how are you", "me llamo": "my name is",
        "mucho gusto": "nice to meet you", "perdón": "excuse me", "lo siento": "i'm sorry",
        "ayuda": "help", "agua": "water", "comida": "food", "casa": "house",
        "coche": "car", "libro": "book", "mesa": "table", "silla": "chair",
        "yo": "me", "tú": "you", "él": "he", "ella": "she",
        "nosotros": "we", "ellos": "they", "esto": "this", "eso": "that",
        "aquí": "here", "allí": "there", "qué": "what", "dónde": "where",
        "cuándo": "when", "por qué": "why", "cómo": "how", "quién": "who",
        "cuál": "which", "prueba": "test", "mensaje": "message", "charla": "chat"
    },
    "en-fr": {
        "hello": "bonjour", "goodbye": "au revoir", "please": "s'il vous plaît",
        "thank you": "merci", "yes": "oui", "no": "non", "good": "bon",
        "bad": "mauvais", "big": "grand", "small": "petit", "hot": "chaud",
        "cold": "froid", "new": "nouveau", "old": "vieux", "young": "jeune",
        "house": "maison", "car": "voiture", "book": "livre", "water": "eau",
        "food": "nourriture", "friend": "ami", "family": "famille", "mother": "mère",
        "father": "père", "work": "travail", "love": "amour", "time": "temps",
        "me": "moi", "you": "tu", "test": "test", "message": "message"
    },
    "fr-en": {
        "bonjour": "hello", "au revoir": "goodbye", "s'il vous plaît": "please",
        "merci": "thank you", "oui": "yes", "non": "no", "bon": "good",
        "mauvais": "bad", "grand": "big", "petit": "small", "moi": "me", "tu": "you"
    },
    "en-de": {
        "hello": "hallo", "goodbye": "auf wiedersehen", "please": "bitte",
        "thank you": "danke", "yes": "ja", "no": "nein", "good": "gut",
        "bad": "schlecht", "big": "groß", "small": "klein", "hot": "heiß",
        "cold": "kalt", "new": "neu", "old": "alt", "young": "jung",
        "house": "haus", "car": "auto", "book": "buch", "water": "wasser",
        "food": "essen", "friend": "freund", "family": "familie", "mother": "mutter",
        "father": "vater", "love": "liebe", "time": "zeit", "me": "ich",
        "you": "du", "test": "test", "message": "nachricht"
    },
    "de-en": {
        "hallo": "hello", "auf wiedersehen": "goodbye", "bitte": "please",
        "danke": "thank you", "ja": "yes", "nein": "no", "gut": "good",
        "schlecht": "bad", "groß": "big", "klein": "small", "ich": "me", "du": "you"
    },
    "en-ja": {
        "hello": "こんにちは", "goodbye": "さようなら", "please": "お願いします",
        "thank you": "ありがとう", "yes": "はい", "no": "いいえ", "good": "良い",
        "bad": "悪い", "big": "大きい", "small": "小さい", "hot": "熱い",
        "cold": "冷たい", "new": "新しい", "old": "古い", "house": "家",
        "water": "水", "food": "食べ物", "friend": "友達", "love": "愛",
        "me": "私", "you": "あなた", "test": "テスト", "message": "メッセージ"
    },
    "ja-en": {
        "こんにちは": "hello", "さようなら": "goodbye", "お願いします": "please",
        "ありがとう": "thank you", "はい": "yes", "いいえ": "no",
        "私": "me", "あなた": "you"
    },
    "en-zh": {
        "hello": "你好", "goodbye": "再见", "please": "请", "thank you": "谢谢",
        "yes": "是", "no": "不", "good": "好", "bad": "坏", "big": "大",
        "small": "小", "hot": "热", "cold": "冷", "new": "新", "old": "旧",
        "house": "房子", "water": "水", "food": "食物", "love": "爱",
        "me": "我", "you": "你", "test": "测试", "message": "消息"
    },
    "zh-en": {
        "你好": "hello", "再见": "goodbye", "请": "please", "谢谢": "thank you",
        "是": "yes", "不": "no", "我": "me", "你": "you"
    },
    "en-pt": {
        "hello": "olá", "goodbye": "adeus", "please": "por favor",
        "thank you": "obrigado", "yes": "sim", "no": "não", "good": "bom",
        "bad": "mau", "big": "grande", "small": "pequeno", "love": "amor",
        "me": "eu", "you": "você", "test": "teste", "message": "mensagem"
    },
    "pt-en": {
        "olá": "hello", "adeus": "goodbye", "por favor": "please",
        "obrigado": "thank you", "sim": "yes", "não": "no",
        "eu": "me", "você": "you"
    },
    "en-hi": {
        "hello": "नमस्ते", "goodbye": "अलविदा", "please": "कृपया",
        "thank you": "धन्यवाद", "yes": "हाँ", "no": "नहीं", "love": "प्यार",
        "me": "मैं", "you": "तुम", "test": "परीक्षण", "message": "संदेश"
    },
    "hi-en": {
        "नमस्ते": "hello", "अलविदा": "goodbye", "कृपया": "please",
        "धन्यवाद": "thank you", "हाँ": "yes", "नहीं": "no",
        "मैं": "me", "तुम": "you"
    },
    "en-ko": {
        "hello": "안녕하세요", "goodbye": "안녕히 가세요", "please": "부탁합니다",
        "thank you": "감사합니다", "yes": "네", "no": "아니오", "love": "사랑",
        "me": "나", "you": "당신", "test": "테스트", "message": "메시지"
    },
    "ko-en": {
        "안녕하세요": "hello", "안녕히 가세요": "goodbye", "부탁합니다": "please",
        "감사합니다": "thank you", "네": "yes", "아니오": "no",
        "나": "me", "당신": "you"
    },
    "en-ar": {
        "hello": "مرحبا", "goodbye": "وداعا", "please": "من فضلك",
        "thank you": "شكرا", "yes": "نعم", "no": "لا", "love": "حب",
        "me": "أنا", "you": "أنت", "test": "اختبار", "message": "رسالة"
    },
    "ar-en": {
        "مرحبا": "hello", "وداعا": "goodbye", "من فضلك": "please",
        "شكرا": "thank you", "نعم": "yes", "لا": "no",
        "أنا": "me", "أنت": "you"
    }
}

def create_database(db_path):
    """Create SQLite database with translations"""
    # Remove existing database
    if os.path.exists(db_path):
        os.remove(db_path)
    
    # Create new database
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Create table
    cursor.execute('''
        CREATE TABLE translations (
            source_lang TEXT NOT NULL,
            target_lang TEXT NOT NULL,
            source_word TEXT NOT NULL,
            translation TEXT NOT NULL,
            PRIMARY KEY (source_lang, target_lang, source_word)
        )
    ''')
    
    # Create index for fast lookups
    cursor.execute('''
        CREATE INDEX idx_lookup ON translations(source_lang, target_lang, source_word)
    ''')
    
    # Insert all translations
    total_count = 0
    for lang_pair, words in translations.items():
        source_lang, target_lang = lang_pair.split('-')
        for source_word, translation in words.items():
            cursor.execute(
                'INSERT INTO translations (source_lang, target_lang, source_word, translation) VALUES (?, ?, ?, ?)',
                (source_lang, target_lang, source_word.lower(), translation)
            )
            total_count += 1
    
    conn.commit()
    conn.close()
    
    print(f"✅ Created translations.db with {total_count} entries")
    print(f"📁 Location: {db_path}")
    
    # Verify
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute('SELECT COUNT(*) FROM translations')
    count = cursor.fetchone()[0]
    print(f"✅ Verified: {count} translations in database")
    conn.close()

if __name__ == '__main__':
    db_path = 'Resources/translations.db'
    os.makedirs('Resources', exist_ok=True)
    create_database(db_path)
