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
  db.execute('DROP TABLE IF EXISTS messages')
  db.execute('DROP TABLE IF EXISTS forum1')
end

def create_tables(db)
  db.execute('CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL,
              pwd_digest TEXT NOT NULL,
              lvl INTEGER)')
  db.execute('CREATE TABLE forums (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              rubrik TEXT NOT NULL)')
  db.execute('CREATE TABLE messages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              forum INTEGER NOT NULL,
              user INTEGER NOT NULL,
              message TEXT)')
end

def populate_tables(db)
  db.execute('INSERT INTO users (username, pwd_digest, lvl) VALUES ("Pinkfix", "$2a$12$LIIaHcnjJk5qSQNOm6GI/uf.YdBm/xMEF5siJkq0vtE14McwKzKYS", 1)')
  db.execute('INSERT INTO users (username, pwd_digest, lvl) VALUES ("Jimmy Pandan", "$2a$12$ktRKfwRBuFfKaWZelPCh5OtnR5UlwHeye4cRiSUm/YrG5.eTQOpdq", 0)')
  db.execute('INSERT INTO forums (rubrik) VALUES ("Återinför Bräckelinjen!")')
  db.execute('INSERT INTO messages (forum,user,message) VALUES (1,2,"Jaa, den var banger!!!")')
end
# Personer
# Pinkfix, Gargamel
# Jimmy Pandan, SourBELTS

seed!(db)





