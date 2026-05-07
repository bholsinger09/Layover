import Foundation
import SQLite3

/// SQLite-based translation database for Language Exchange feature
public class TranslationDatabase {
    private static let shared = TranslationDatabase()
    private static let queue = DispatchQueue(label: "com.layover.translationdb", attributes: .concurrent)
    
    private var db: OpaquePointer?
    private var isInitialized = false
    
    private init() {
        openDatabase()
    }
    
    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }
    
    /// Open and initialize the database
    private func openDatabase() {
        // Try to open from bundle resources first
        if let dbPath = Bundle.main.path(forResource: "translations", ofType: "db") {
            if sqlite3_open(dbPath, &db) == SQLITE_OK {
                isInitialized = true
                return
            }
        }
        
        // Fallback: create in-memory database
        if sqlite3_open(":memory:", &db) == SQLITE_OK {
            createInMemoryDatabase()
        }
    }
    
    /// Create in-memory database as fallback
    private func createInMemoryDatabase() {
        guard let db = db else { return }
        
        // Create table
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS translations (
            source_lang TEXT NOT NULL,
            target_lang TEXT NOT NULL,
            source_word TEXT NOT NULL,
            translation TEXT NOT NULL,
            PRIMARY KEY (source_lang, target_lang, source_word)
        );
        CREATE INDEX IF NOT EXISTS idx_lookup ON translations(source_lang, target_lang, source_word);
        """
        
        var errMsg: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, createTableSQL, nil, nil, &errMsg) == SQLITE_OK else {
            if let errMsg = errMsg {
                print("TranslationDatabase: Error creating table: \(String(cString: errMsg))")
                sqlite3_free(errMsg)
            }
            return
        }
        
        // Populate with translations
        populateTranslations(db: db)
        isInitialized = true
    }
    
    /// Populate database with translations (fallback when no database file found)
    private func populateTranslations(db: OpaquePointer) {
        let insertSQL = "INSERT OR IGNORE INTO translations (source_lang, target_lang, source_word, translation) VALUES (?, ?, ?, ?)"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK else {
            return
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil)
        
        // Add common English-Spanish translations
        let enEs = [
            "hello": "hola", "goodbye": "adiós", "please": "por favor", "thank you": "gracias",
            "yes": "sí", "no": "no", "good": "bueno", "bad": "malo",
            "test": "prueba", "me": "yo", "you": "tú", "message": "mensaje"
        ]
        
        for (source, target) in enEs {
            insertTranslation(statement: statement, from: "en", to: "es", source: source, translation: target)
        }
        
        // Add reverse
        for (target, source) in enEs {
            insertTranslation(statement: statement, from: "es", to: "en", source: source, translation: target)
        }
        
        sqlite3_exec(db, "COMMIT", nil, nil, nil)
    }
    
    /// Insert a single translation
    private func insertTranslation(statement: OpaquePointer?, from: String, to: String, source: String, translation: String) {
        guard let statement = statement else { return }
        sqlite3_bind_text(statement, 1, (from as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (to as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 3, (source as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 4, (translation as NSString).utf8String, -1, nil)
        sqlite3_step(statement)
        sqlite3_reset(statement)
    }
    
    /// Get translation for a word
    public static func translate(word: String, from: String, to: String) -> String? {
        return queue.sync {
            guard shared.isInitialized, let db = shared.db else { return nil }
            return shared.lookup(word: word.lowercased(), from: from, to: to, db: db)
        }
    }
    
    /// Perform database lookup
    private func lookup(word: String, from: String, to: String, db: OpaquePointer) -> String? {
        let querySQL = "SELECT translation FROM translations WHERE source_lang = ? AND target_lang = ? AND source_word = ?"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK else {
            return nil
        }
        
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (from as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (to as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 3, (word as NSString).utf8String, -1, nil)
        
        if sqlite3_step(statement) == SQLITE_ROW {
            if let cString = sqlite3_column_text(statement, 0) {
                return String(cString: cString)
            }
        }
        
        return nil
    }
}
