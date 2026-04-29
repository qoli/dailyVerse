#!/usr/bin/env python3
import argparse
import re
import sqlite3
import urllib.request
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "Data" / "Sources"
OUTPUT_DB = ROOT / "dailyVerse" / "Resources" / "bible.sqlite"

SOURCES = {
    "zh-Hant": {
        "name": "Chinese Union Version 1989 Traditional",
        "language": "zh-Hant",
        "url": "https://ebible.org/Scriptures/cmn-cu89t_usfm.zip",
        "zip": "cmn-cu89t_usfm.zip",
    },
    "zh-Hans": {
        "name": "Chinese Union Version 1989 Simplified",
        "language": "zh-Hans",
        "url": "https://ebible.org/Scriptures/cmn-cu89s_usfm.zip",
        "zip": "cmn-cu89s_usfm.zip",
    },
    "en": {
        "name": "World English Bible",
        "language": "en",
        "url": "https://ebible.org/Scriptures/engwebp_usfm.zip",
        "zip": "engwebp_usfm.zip",
    },
}

BOOKS = [
    ("GEN", "創世記", "创世记", "Genesis"),
    ("EXO", "出埃及記", "出埃及记", "Exodus"),
    ("LEV", "利未記", "利未记", "Leviticus"),
    ("NUM", "民數記", "民数记", "Numbers"),
    ("DEU", "申命記", "申命记", "Deuteronomy"),
    ("JOS", "約書亞記", "约书亚记", "Joshua"),
    ("JDG", "士師記", "士师记", "Judges"),
    ("RUT", "路得記", "路得记", "Ruth"),
    ("1SA", "撒母耳記上", "撒母耳记上", "1 Samuel"),
    ("2SA", "撒母耳記下", "撒母耳记下", "2 Samuel"),
    ("1KI", "列王紀上", "列王纪上", "1 Kings"),
    ("2KI", "列王紀下", "列王纪下", "2 Kings"),
    ("1CH", "歷代志上", "历代志上", "1 Chronicles"),
    ("2CH", "歷代志下", "历代志下", "2 Chronicles"),
    ("EZR", "以斯拉記", "以斯拉记", "Ezra"),
    ("NEH", "尼希米記", "尼希米记", "Nehemiah"),
    ("EST", "以斯帖記", "以斯帖记", "Esther"),
    ("JOB", "約伯記", "约伯记", "Job"),
    ("PSA", "詩篇", "诗篇", "Psalms"),
    ("PRO", "箴言", "箴言", "Proverbs"),
    ("ECC", "傳道書", "传道书", "Ecclesiastes"),
    ("SNG", "雅歌", "雅歌", "Song of Songs"),
    ("ISA", "以賽亞書", "以赛亚书", "Isaiah"),
    ("JER", "耶利米書", "耶利米书", "Jeremiah"),
    ("LAM", "耶利米哀歌", "耶利米哀歌", "Lamentations"),
    ("EZK", "以西結書", "以西结书", "Ezekiel"),
    ("DAN", "但以理書", "但以理书", "Daniel"),
    ("HOS", "何西阿書", "何西阿书", "Hosea"),
    ("JOL", "約珥書", "约珥书", "Joel"),
    ("AMO", "阿摩司書", "阿摩司书", "Amos"),
    ("OBA", "俄巴底亞書", "俄巴底亚书", "Obadiah"),
    ("JON", "約拿書", "约拿书", "Jonah"),
    ("MIC", "彌迦書", "弥迦书", "Micah"),
    ("NAM", "那鴻書", "那鸿书", "Nahum"),
    ("HAB", "哈巴谷書", "哈巴谷书", "Habakkuk"),
    ("ZEP", "西番雅書", "西番雅书", "Zephaniah"),
    ("HAG", "哈該書", "哈该书", "Haggai"),
    ("ZEC", "撒迦利亞書", "撒迦利亚书", "Zechariah"),
    ("MAL", "瑪拉基書", "玛拉基书", "Malachi"),
    ("MAT", "馬太福音", "马太福音", "Matthew"),
    ("MRK", "馬可福音", "马可福音", "Mark"),
    ("LUK", "路加福音", "路加福音", "Luke"),
    ("JHN", "約翰福音", "约翰福音", "John"),
    ("ACT", "使徒行傳", "使徒行传", "Acts"),
    ("ROM", "羅馬書", "罗马书", "Romans"),
    ("1CO", "哥林多前書", "哥林多前书", "1 Corinthians"),
    ("2CO", "哥林多後書", "哥林多后书", "2 Corinthians"),
    ("GAL", "加拉太書", "加拉太书", "Galatians"),
    ("EPH", "以弗所書", "以弗所书", "Ephesians"),
    ("PHP", "腓立比書", "腓立比书", "Philippians"),
    ("COL", "歌羅西書", "歌罗西书", "Colossians"),
    ("1TH", "帖撒羅尼迦前書", "帖撒罗尼迦前书", "1 Thessalonians"),
    ("2TH", "帖撒羅尼迦後書", "帖撒罗尼迦后书", "2 Thessalonians"),
    ("1TI", "提摩太前書", "提摩太前书", "1 Timothy"),
    ("2TI", "提摩太後書", "提摩太后书", "2 Timothy"),
    ("TIT", "提多書", "提多书", "Titus"),
    ("PHM", "腓利門書", "腓利门书", "Philemon"),
    ("HEB", "希伯來書", "希伯来书", "Hebrews"),
    ("JAS", "雅各書", "雅各书", "James"),
    ("1PE", "彼得前書", "彼得前书", "1 Peter"),
    ("2PE", "彼得後書", "彼得后书", "2 Peter"),
    ("1JN", "約翰一書", "约翰一书", "1 John"),
    ("2JN", "約翰二書", "约翰二书", "2 John"),
    ("3JN", "約翰三書", "约翰三书", "3 John"),
    ("JUD", "猶大書", "犹大书", "Jude"),
    ("REV", "啟示錄", "启示录", "Revelation"),
]

DAILY_REFERENCES = [
    ("JHN", 3, 16, 16), ("PSA", 23, 1, 1), ("PHP", 4, 13, 13), ("ROM", 8, 28, 28),
    ("JER", 29, 11, 11), ("PRO", 3, 5, 6), ("ISA", 41, 10, 10), ("MAT", 11, 28, 28),
    ("PSA", 46, 1, 1), ("ROM", 12, 2, 2), ("GAL", 5, 22, 23), ("HEB", 11, 1, 1),
    ("JAS", 1, 5, 5), ("1PE", 5, 7, 7), ("1JN", 4, 19, 19), ("REV", 21, 4, 4),
    ("PSA", 119, 105, 105), ("ISA", 40, 31, 31), ("MAT", 5, 16, 16), ("MAT", 6, 33, 33),
    ("LUK", 6, 31, 31), ("JHN", 14, 6, 6), ("JHN", 14, 27, 27), ("ACT", 1, 8, 8),
    ("ROM", 5, 8, 8), ("ROM", 10, 9, 9), ("1CO", 13, 4, 7), ("2CO", 5, 17, 17),
    ("EPH", 2, 8, 9), ("EPH", 6, 10, 10), ("COL", 3, 23, 23), ("1TH", 5, 16, 18),
    ("2TI", 1, 7, 7), ("HEB", 4, 16, 16), ("JAS", 1, 17, 17), ("1PE", 2, 9, 9),
    ("1JN", 1, 9, 9), ("PSA", 19, 14, 14), ("PSA", 27, 1, 1), ("PSA", 34, 8, 8),
    ("PSA", 37, 4, 4), ("PSA", 51, 10, 10), ("PSA", 91, 1, 2), ("PRO", 16, 9, 9),
    ("ISA", 26, 3, 3), ("ISA", 53, 5, 5), ("MIC", 6, 8, 8), ("MAT", 7, 7, 8),
    ("MAT", 22, 37, 39), ("MRK", 10, 45, 45), ("LUK", 12, 32, 32), ("JHN", 8, 12, 12),
    ("JHN", 15, 5, 5), ("ROM", 15, 13, 13), ("1CO", 10, 13, 13), ("2CO", 12, 9, 9),
    ("GAL", 2, 20, 20), ("PHP", 4, 6, 7), ("COL", 3, 16, 16), ("HEB", 13, 8, 8),
    ("JAS", 4, 8, 8), ("1PE", 3, 15, 15), ("1JN", 3, 18, 18), ("JUD", 1, 24, 25),
]

BOOK_ID_BY_OSIS = {osis: index + 1 for index, (osis, _, _, _) in enumerate(BOOKS)}
OSIS_BY_USFM = {"PSA": "PSA", "SNG": "SNG"}


def download_sources():
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    for source in SOURCES.values():
        target = SOURCE_DIR / source["zip"]
        if target.exists():
            continue
        print(f"Downloading {source['url']}")
        urllib.request.urlretrieve(source["url"], target)


def normalize_osis(usfm_code):
    return OSIS_BY_USFM.get(usfm_code, usfm_code)


def strip_usfm(text):
    text = re.sub(r"\\(?:f|x)\s+.*?\\(?:f|x)\*", "", text, flags=re.DOTALL)
    text = re.sub(r"\\w\s+([^|\\]+)(?:\|[^\\]*)?\\w\*", r"\1", text)
    text = re.sub(r"\\\+?w\s+([^|\\]+)(?:\|[^\\]*)?\\\+?w\*", r"\1", text)
    text = re.sub(r"\\(?:add|bd|em|it|nd|pn|qt|sc|wj)\s+([^\\]*?)\\(?:add|bd|em|it|nd|pn|qt|sc|wj)\*", r"\1", text)
    text = re.sub(r"\\[a-z0-9]+(?:-[a-z0-9]+)?\*", "", text)
    text = re.sub(r"\\[a-z0-9]+(?:-[a-z0-9]+)?(?:\s+)?", "", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def parse_usfm(content):
    content = re.sub(r"\\(?:f|x)\s+.*?\\(?:f|x)\*", "", content, flags=re.DOTALL)
    verses = []
    chapter = None
    current_verse = None
    current_text = []

    def flush():
        if chapter is None or current_verse is None:
            return
        text = strip_usfm(" ".join(current_text))
        if text:
            verses.append((chapter, current_verse, text))

    for raw_line in content.splitlines():
        line = raw_line.strip()
        if not line:
            continue

        chapter_match = re.match(r"\\c\s+(\d+)", line)
        if chapter_match:
            flush()
            chapter = int(chapter_match.group(1))
            current_verse = None
            current_text = []
            continue

        verse_match = re.match(r"\\v\s+(\d+)(?:-\d+)?\s*(.*)", line)
        if verse_match:
            flush()
            current_verse = int(verse_match.group(1))
            current_text = [verse_match.group(2)]
            continue

        if current_verse is not None and not re.match(r"\\(?:id|ide|h|toc|mt|ms|s|r|cl|cp|rem|sts)\b", line):
            current_text.append(line)

    flush()
    return verses


def iter_book_files(zip_path):
    with zipfile.ZipFile(zip_path) as archive:
        for name in archive.namelist():
            filename = Path(name).name
            match = re.match(r"\d+-([123]?[A-Z]{2,3})[a-z0-9-]*\.usfm$", filename)
            if not match:
                continue
            osis = normalize_osis(match.group(1))
            if osis not in BOOK_ID_BY_OSIS:
                continue
            yield osis, archive.read(name).decode("utf-8-sig")


def build_database(output_db):
    output_db.parent.mkdir(parents=True, exist_ok=True)
    if output_db.exists():
        output_db.unlink()

    connection = sqlite3.connect(output_db)
    try:
        connection.executescript(
            """
            PRAGMA journal_mode=OFF;
            PRAGMA synchronous=OFF;
            CREATE TABLE translations (
                id INTEGER PRIMARY KEY,
                code TEXT NOT NULL UNIQUE,
                name TEXT NOT NULL,
                language TEXT NOT NULL,
                source_url TEXT NOT NULL
            );
            CREATE TABLE books (
                id INTEGER PRIMARY KEY,
                osis TEXT NOT NULL UNIQUE,
                sort_order INTEGER NOT NULL,
                name_zh_hant TEXT NOT NULL,
                name_zh_hans TEXT NOT NULL,
                name_en TEXT NOT NULL
            );
            CREATE TABLE verses (
                translation_id INTEGER NOT NULL,
                book_id INTEGER NOT NULL,
                chapter INTEGER NOT NULL,
                verse INTEGER NOT NULL,
                text TEXT NOT NULL,
                PRIMARY KEY (translation_id, book_id, chapter, verse)
            );
            CREATE TABLE daily_verses (
                day_index INTEGER PRIMARY KEY,
                book_id INTEGER NOT NULL,
                chapter INTEGER NOT NULL,
                verse_start INTEGER NOT NULL,
                verse_end INTEGER NOT NULL
            );
            CREATE INDEX verses_lookup ON verses (translation_id, book_id, chapter, verse);
            """
        )

        for index, (osis, name_hant, name_hans, name_en) in enumerate(BOOKS, start=1):
            connection.execute(
                "INSERT INTO books VALUES (?, ?, ?, ?, ?, ?)",
                (index, osis, index, name_hant, name_hans, name_en),
            )

        for translation_id, (code, source) in enumerate(SOURCES.items(), start=1):
            connection.execute(
                "INSERT INTO translations VALUES (?, ?, ?, ?, ?)",
                (translation_id, code, source["name"], source["language"], source["url"]),
            )
            for osis, content in iter_book_files(SOURCE_DIR / source["zip"]):
                book_id = BOOK_ID_BY_OSIS[osis]
                rows = [
                    (translation_id, book_id, chapter, verse, text)
                    for chapter, verse, text in parse_usfm(content)
                ]
                connection.executemany("INSERT INTO verses VALUES (?, ?, ?, ?, ?)", rows)

        for day_index in range(1, 367):
            osis, chapter, verse_start, verse_end = DAILY_REFERENCES[(day_index - 1) % len(DAILY_REFERENCES)]
            connection.execute(
                "INSERT INTO daily_verses VALUES (?, ?, ?, ?, ?)",
                (day_index, BOOK_ID_BY_OSIS[osis], chapter, verse_start, verse_end),
            )

        connection.execute("PRAGMA user_version=1")
        connection.commit()
    finally:
        connection.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--download", action="store_true", help="download missing USFM source archives")
    parser.add_argument("--output", type=Path, default=OUTPUT_DB)
    args = parser.parse_args()

    if args.download:
        download_sources()
    build_database(args.output)
    size_mb = args.output.stat().st_size / 1024 / 1024
    print(f"Built {args.output} ({size_mb:.2f} MB)")


if __name__ == "__main__":
    main()
