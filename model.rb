module Model

#
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

def error(reg_login_delete, error_message)
  session[:error] = error_message
  redirect('/account/#{reg_login_delete}')
end


def validateLength(username, password)
  if username.length < 3
    error("register","För kort användarnamn. Måste vara mellan 3 och 30 karaktärer")
  elsif username.length > 30
    error("register","För långt användarnamn. Måste vara mellan 3 och 30 karaktärer")
  end
  if password.to_i == password
    error("register","Lösenord får ej bestå av endast siffror!")
  elsif password.length < 8
    error("register","För kort lösenord. Måste vara mellan 8 och 40 karaktärer")
  elsif password.length > 40
    error("register","För långt lösenord. Måste vara mellan 8 och 40 karaktärer")
  end
end

def sättUppAnvändare(user, pwd, lvl)
  db = getDB("db/railed.db")
  pwd_digest = BCrypt::Password.create(pwd)
  session[:logged_in] = true
  user_id = db.execute("SELECT * FROM users").length + 1
  session[:user_id] = user_id
  session[:error] = "W"
  db.execute('INSERT INTO users (username, pwd_digest, lvl) VALUES (?,?,?)',[user, pwd_digest,lvl])
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

def ddosBuffer()
  if session[:time]
    time = Time.now
    if time - session[:time] < 3
      sleep(3)
    end
  end
  session[:time] = Time.now
end

def getForumsFav(userid)
  db = getDB("db/railed.db")
  everything = db.execute('SELECT * FROM forums LEFT JOIN favoriter ON forums.id = favoriter.forum_id WHERE favoriter.user_id = ?', userid)
  return everything
end

def getForumsNotFav(userid)
  db = getDB("db/railed.db")
  everything = db.execute('SELECT * FROM forums LEFT JOIN favoriter ON forums.id = favoriter.forum_id WHERE NOT favoriter.user_id = ? OR favoriter.user_id IS NULL', userid)
  return everything
end

def getForumsAll()
  db = getDB("db/railed.db")
  everything = db.execute('SELECT * FROM forums LEFT JOIN favoriter ON forums.id = favoriter.forum_id')
  return everything
end

def favourite(f_id, u_id)
  db = getDB("db/railed.db")
  db.execute("INSERT INTO favoriter (forum_id, user_id) VALUES (?,?)",[f_id,u_id])
end

def unfavourite(f_id, u_id)
  db = getDB("db/railed.db")
  db.execute("DELETE FROM favoriter WHERE forum_id=? AND user_id=?",[f_id,u_id])
end