def getDB(database)
  db = SQLite3::Database.new(database)
  db.results_as_hash = true
  return db
end

def backgroundCheck(user_id)
  db = getDB("db/railed.db")
  if db.execute("SELECT lvl FROM users WHERE id=?",user_id).first["lvl"] == 1
    return true
  end
  return false
end

def sättUppAnvändare(username, pwd_digest, lvl) 
  db = getDB("db/railed.db")
  pwd_digest = BCrypt::Password.create(pwd)
  session[:logged_in] = true
  user_id = db.execute("SELECT id FROM users WHERE username=?", user)
  session[:user_id] = user_id
  session[:error] = "W"
  db.execute('INSERT INTO users (username, pwd_digest, lvl) VALUES (?,?,?)',[username, pwd_digest,lvl])
end

def getIdInfo(id)
  db = getDB("db/railed.db")
  return db.execute("SELECT * FROM users WHERE id=?",id).first
end

def getUserInfo(user)
  db = getDB("db/railed.db")
  return db.execute("SELECT * FROM users WHERE username=?",user).first
end

def logIn(admin)
  if admin == 1
    session[:admin] = true
  else
    session[:admin] = false
  end
  session[:logged_in] = true
end

def getForumsFromID(id)
  db = getDB("db/railed.db")
  return db.execute("SELECT rubrik FROM forums WHERE id=?",@id).first
end

def getChatHistory(id)
  db = getDB("db/railed.db")
  return db.execute("SELECT messages.id,username,message FROM messages LEFT JOIN users on messages.user = users.id WHERE forum = ?", @id)
end

def createForum(forum_name)
  db = getDB("db/railed.db")
  db.execute("INSERT INTO forums (rubrik) VALUES (?)", forum_name)
end

def getForumFromRubrik(forum_name)
  db = getDB("db/railed.db")
  return db.execute("SELECT * FROM forums WHERE rubrik = ?", rubr).first
end

def insertMessage(forum, user, message)
  db = getDB("db/railed.db")
  db.execute('INSERT INTO messages (forum,user,message) VALUES (?,?,?)',[forum, user, message])
end

def deleteMessage(id)
  db = getDB("db/railed.db")
  db.execute("DELETE FROM messages WHERE id = ?",id)
end

def resetSession()
  session[:logged_in] = false
  session[:admin] = false
  session[:user_id] = 0
end

def eraseUser(user_id)
  db = getDB("db/railed.db")
  name = getIdInfo(user_id)["username"]
  db.execute("UPDATE users SET username='Deleted User',pwd_digest=? WHERE id=?", [name, user_id])
end