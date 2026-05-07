import Foundation

/// Dictionary-based translation database with lazy loading to avoid compiler timeout
public class TranslationDatabase {
    
    /// Get translation for a word
    public static func translate(word: String, from: String, to: String) -> String? {
        let key = "\(from)-\(to)"
        guard let dict = dictionaries[key] else { return nil }
        return dict[word.lowercased()]
    }
    
    // Split into multiple small dictionaries to avoid WMO timeout
    // Each dictionary is loaded lazily only when accessed
    
    private static let enEs: [String: String] = [
        "hello": "hola", "goodbye": "adiós", "please": "por favor", "thank you": "gracias",
        "yes": "sí", "no": "no", "good": "bueno", "bad": "malo", "big": "grande",
        "small": "pequeño", "hot": "caliente", "cold": "frío", "new": "nuevo",
        "old": "viejo", "young": "joven", "good morning": "buenos días",
        "good night": "buenas noches", "how are you": "cómo estás", "my name is": "me llamo",
        "nice to meet you": "mucho gusto", "excuse me": "perdón", "i'm sorry": "lo siento",
        "help": "ayuda", "water": "agua", "food": "comida", "house": "casa",
        "car": "coche", "book": "libro", "table": "mesa", "chair": "silla"
    ]
    
    private static let esEn: [String: String] = [
        "hola": "hello", "adiós": "goodbye", "por favor": "please", "gracias": "thank you",
        "sí": "yes", "no": "no", "bueno": "good", "malo": "bad", "grande": "big",
        "pequeño": "small", "caliente": "hot", "frío": "cold", "nuevo": "new",
        "viejo": "old", "joven": "young", "buenos días": "good morning",
        "buenas noches": "good night", "cómo estás": "how are you", "me llamo": "my name is",
        "mucho gusto": "nice to meet you", "perdón": "excuse me", "lo siento": "i'm sorry",
        "ayuda": "help", "agua": "water", "comida": "food", "casa": "house",
        "coche": "car", "libro": "book", "mesa": "table", "silla": "chair"
    ]
    
    private static let enFr: [String: String] = [
        "hello": "bonjour", "goodbye": "au revoir", "please": "s'il vous plaît",
        "thank you": "merci", "yes": "oui", "no": "non", "good": "bon",
        "bad": "mauvais", "big": "grand", "small": "petit", "hot": "chaud",
        "cold": "froid", "new": "nouveau", "old": "vieux", "young": "jeune"
    ]
    
    private static let frEn: [String: String] = [
        "bonjour": "hello", "au revoir": "goodbye", "s'il vous plaît": "please",
        "merci": "thank you", "oui": "yes", "non": "no", "bon": "good",
        "mauvais": "bad", "grand": "big", "petit": "small"
    ]
    
    private static let enDe: [String: String] = [
        "hello": "hallo", "goodbye": "auf wiedersehen", "please": "bitte",
        "thank you": "danke", "yes": "ja", "no": "nein", "good": "gut",
        "bad": "schlecht", "big": "groß", "small": "klein"
    ]
    
    private static let deEn: [String: String] = [
        "hallo": "hello", "auf wiedersehen": "goodbye", "bitte": "please",
        "danke": "thank you", "ja": "yes", "nein": "no", "gut": "good",
        "schlecht": "bad", "groß": "big", "klein": "small"
    ]
    
    private static let enJa: [String: String] = [
        "hello": "こんにちは", "goodbye": "さようなら", "please": "お願いします",
        "thank you": "ありがとう", "yes": "はい", "no": "いいえ"
    ]
    
    private static let jaEn: [String: String] = [
        "こんにちは": "hello", "さようなら": "goodbye", "お願いします": "please",
        "ありがとう": "thank you", "はい": "yes", "いいえ": "no"
    ]
    
    private static let enZh: [String: String] = [
        "hello": "你好", "goodbye": "再见", "please": "请", "thank you": "谢谢",
        "yes": "是", "no": "不"
    ]
    
    private static let zhEn: [String: String] = [
        "你好": "hello", "再见": "goodbye", "请": "please", "谢谢": "thank you",
        "是": "yes", "不": "no"
    ]
    
    private static let enPt: [String: String] = [
        "hello": "olá", "goodbye": "adeus", "please": "por favor",
        "thank you": "obrigado", "yes": "sim", "no": "não"
    ]
    
    private static let ptEn: [String: String] = [
        "olá": "hello", "adeus": "goodbye", "por favor": "please",
        "obrigado": "thank you", "sim": "yes", "não": "no"
    ]
    
    private static let enHi: [String: String] = [
        "hello": "नमस्ते", "goodbye": "अलविदा", "please": "कृपया",
        "thank you": "धन्यवाद", "yes": "हाँ", "no": "नहीं"
    ]
    
    private static let hiEn: [String: String] = [
        "नमस्ते": "hello", "अलविदा": "goodbye", "कृपया": "please",
        "धन्यवाद": "thank you", "हाँ": "yes", "नहीं": "no"
    ]
    
    private static let enKo: [String: String] = [
        "hello": "안녕하세요", "goodbye": "안녕히 가세요", "please": "부탁합니다",
        "thank you": "감사합니다", "yes": "네", "no": "아니오"
    ]
    
    private static let koEn: [String: String] = [
        "안녕하세요": "hello", "안녕히 가세요": "goodbye", "부탁합니다": "please",
        "감사합니다": "thank you", "네": "yes", "아니오": "no"
    ]
    
    private static let enAr: [String: String] = [
        "hello": "مرحبا", "goodbye": "وداعا", "please": "من فضلك",
        "thank you": "شكرا", "yes": "نعم", "no": "لا"
    ]
    
    private static let arEn: [String: String] = [
        "مرحبا": "hello", "وداعا": "goodbye", "من فضلك": "please",
        "شكرا": "thank you", "نعم": "yes", "لا": "no"
    ]
    
    // Lazy dictionary lookup
    private static let dictionaries: [String: [String: String]] = [
        "en-es": enEs, "es-en": esEn,
        "en-fr": enFr, "fr-en": frEn,
        "en-de": enDe, "de-en": deEn,
        "en-ja": enJa, "ja-en": jaEn,
        "en-zh": enZh, "zh-en": zhEn,
        "en-pt": enPt, "pt-en": ptEn,
        "en-hi": enHi, "hi-en": hiEn,
        "en-ko": enKo, "ko-en": koEn,
        "en-ar": enAr, "ar-en": arEn
    ]
}
