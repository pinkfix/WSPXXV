require 'sqlite3'

db = SQLite3::Database.new("db/railed.db")


def seed!(db)
  puts "Using db file: db/railed.db"
  puts "🧹 Dropping old tables..."
  drop_tables(db)
  puts "🧱 Creating tables..."
  create_tables(db)
  puts "🍎 Populating tables..."
  populate_tables(db)
  puts "✅ Done seeding the database!"
end

def drop_tables(db)
  db.execute('DROP TABLE IF EXISTS users')
  db.execute('DROP TABLE IF EXISTS forums')
end

def create_tables(db)
  db.execute('CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL,
              pwd_digest TEXT NOT NULL,
              lvl BOOLEAN)')
  #db.execute('CREATE TABLE forums (
   #           id INTEGER PRIMARY KEY AUTOINCREMENT,
    #          name TEXT NOT NULL)')
end

def populate_tables(db)
  db.execute('INSERT INTO users (username, pwd_digest, lvl) VALUES ("Pinkfix", "$2a$12$LIIaHcnjJk5qSQNOm6GI/uf.YdBm/xMEF5siJkq0vtE14McwKzKYS", true)')
  #db.execute('INSERT INTO forums (name) VALUES ("Återinför Bräckelinjen!!!1!!1!1!!11!!")')
end


seed!(db)





