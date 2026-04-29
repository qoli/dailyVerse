import Foundation
import SQLite3

struct BibleChapterVerse {
    let number: Int
    let text: String
}

struct BibleDailyVerse {
    let bookID: Int
    let bookName: String
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int
    let text: String

    var referenceText: String {
        if verseStart == verseEnd {
            return "\(bookName) \(chapter):\(verseStart)"
        }
        return "\(bookName) \(chapter):\(verseStart)-\(verseEnd)"
    }

    var displayText: String {
        return "\(text)\n\n\(referenceText)"
    }
}

enum BibleDatabaseError: Error, LocalizedError {
    case missingDatabase
    case openFailed(String)
    case queryFailed(String)
    case missingDailyVerse

    var errorDescription: String? {
        switch self {
        case .missingDatabase:
            return "找不到本地聖經資料庫"
        case .openFailed(let message):
            return "開啟本地聖經資料庫失敗：\(message)"
        case .queryFailed(let message):
            return "讀取本地聖經資料庫失敗：\(message)"
        case .missingDailyVerse:
            return "找不到今日經文"
        }
    }
}

final class BibleDatabase {
    static let shared = BibleDatabase()

    private var database: OpaquePointer?
    private let bundle: Bundle

    private init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    deinit {
        if let database = database {
            sqlite3_close(database)
        }
    }

    static func preferredTranslationCode() -> String {
        let language = Bundle.main.preferredLocalizations.first ?? "en"
        switch language {
        case "zh-Hans", "zh-Hans-US", "zh-Hans-CN":
            return "zh-Hans"
        case "zh-Hant", "zh-Hant-CN", "zh-TW", "zh-HK":
            return "zh-Hant"
        default:
            return "en"
        }
    }

    func dailyVerse(date: Date = Date(), translationCode: String = BibleDatabase.preferredTranslationCode()) throws -> BibleDailyVerse {
        let calendar = Calendar.current
        let dayIndex = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let sql = """
            SELECT d.book_id, d.chapter, d.verse_start, d.verse_end,
                   CASE ?
                       WHEN 'zh-Hant' THEN b.name_zh_hant
                       WHEN 'zh-Hans' THEN b.name_zh_hans
                       ELSE b.name_en
                   END AS book_name
            FROM daily_verses d
            JOIN books b ON b.id = d.book_id
            WHERE d.day_index = ?
            LIMIT 1
        """
        let statement = try prepare(sql)
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, translationCode, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 2, Int32(dayIndex))

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw BibleDatabaseError.missingDailyVerse
        }

        let bookID = Int(sqlite3_column_int(statement, 0))
        let chapter = Int(sqlite3_column_int(statement, 1))
        let verseStart = Int(sqlite3_column_int(statement, 2))
        let verseEnd = Int(sqlite3_column_int(statement, 3))
        let bookName = columnText(statement, 4)
        let text = try verseText(
            translationCode: translationCode,
            bookID: bookID,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd
        )

        return BibleDailyVerse(
            bookID: bookID,
            bookName: bookName,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd,
            text: text
        )
    }

    func chapter(bookID: Int, chapter: Int, translationCode: String = BibleDatabase.preferredTranslationCode()) throws -> [BibleChapterVerse] {
        let sql = """
            SELECT v.verse, v.text
            FROM verses v
            JOIN translations t ON t.id = v.translation_id
            WHERE t.code = ? AND v.book_id = ? AND v.chapter = ?
            ORDER BY v.verse
        """
        let statement = try prepare(sql)
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, translationCode, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 2, Int32(bookID))
        sqlite3_bind_int(statement, 3, Int32(chapter))

        var result: [BibleChapterVerse] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            result.append(BibleChapterVerse(
                number: Int(sqlite3_column_int(statement, 0)),
                text: columnText(statement, 1)
            ))
        }
        return result
    }

    private func verseText(translationCode: String, bookID: Int, chapter: Int, verseStart: Int, verseEnd: Int) throws -> String {
        let sql = """
            SELECT v.text
            FROM verses v
            JOIN translations t ON t.id = v.translation_id
            WHERE t.code = ? AND v.book_id = ? AND v.chapter = ? AND v.verse BETWEEN ? AND ?
            ORDER BY v.verse
        """
        let statement = try prepare(sql)
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, translationCode, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 2, Int32(bookID))
        sqlite3_bind_int(statement, 3, Int32(chapter))
        sqlite3_bind_int(statement, 4, Int32(verseStart))
        sqlite3_bind_int(statement, 5, Int32(verseEnd))

        var parts: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            parts.append(columnText(statement, 0))
        }
        return parts.joined(separator: " ")
    }

    private func prepare(_ sql: String) throws -> OpaquePointer? {
        try openIfNeeded()
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw BibleDatabaseError.queryFailed(lastErrorMessage)
        }
        return statement
    }

    private func openIfNeeded() throws {
        if database != nil {
            return
        }

        guard let databaseURL = bundle.url(forResource: "bible", withExtension: "sqlite") else {
            throw BibleDatabaseError.missingDatabase
        }

        var openedDatabase: OpaquePointer?
        guard sqlite3_open_v2(databaseURL.path, &openedDatabase, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            let message = openedDatabase.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            throw BibleDatabaseError.openFailed(message)
        }
        database = openedDatabase
    }

    private var lastErrorMessage: String {
        guard let database = database else {
            return "database is not open"
        }
        return String(cString: sqlite3_errmsg(database))
    }

    private func columnText(_ statement: OpaquePointer?, _ index: Int32) -> String {
        guard let text = sqlite3_column_text(statement, index) else {
            return ""
        }
        return String(cString: text)
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
