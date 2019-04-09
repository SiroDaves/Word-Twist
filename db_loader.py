import sqlite3

conn = sqlite3.connect('assets/words.sqlite')
curs = conn.cursor()

curs.execute('SELECT rowid,* FROM words_en')
rows = curs.fetchall()
for r in rows:
    if r[1] is None:
        continue
    s = ''.join(sorted(r[1]))
    print(r[1])
    existing = curs.execute('SELECT rowid,* FROM words_fts WHERE sorted = ?', (s,)).fetchone()
    if (existing):
        curs.execute('UPDATE words_fts SET word_ids = ? WHERE rowid = ?',
                     (existing[2] + ',' + str(r[0]), str(existing[0], )))
    else:
        curs.execute('INSERT INTO words_fts (sorted, word_ids) VALUES (?, ?)', (s, str(r[0])))

print(curs.execute('SELECT COUNT(*) FROM words_fts').fetchone())

conn.commit()
conn.close()
