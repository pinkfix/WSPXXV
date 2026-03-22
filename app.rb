require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

# BEFORE-BLOCK

# Definiera ett before-block som kollar om användaren är inloggad och admin



# DRY-Funktioner



#Helper functions

before do
  def getDB(database)
    db = SQLite3::Database.new(database)
    db.results_as_hash = true
    return db
  end

  def backgroundCheck(user_id)
    db = getDB("db/railed.db")
    if db.execute("SELECT lvl FROM users WHERE id=?",user_id).first["lvl"] == 0
      return false
    else
      return true
    end
  end
end


# FUNKTIONER RELATERADE TILL ANVÄNDARSYSTEMET

get('/register') do
  slim(:signup)
end

post('/register') do
  db = getDB("db/railed.db")
  user = params["user"]
  pwd = params["pwd"]
  pwd_confirm = params["pwd_confirm"]
  lvl = 0
  session[:admin] = 0
  if params["admin"]
    lvl = 1
    session[:admin] = 1
  end

  
  result = db.execute("SELECT id FROM users WHERE username=?",user)

  if result.empty?
    if pwd == pwd_confirm
      pwd_digest = BCrypt::Password.create(pwd)
      session[:logged_in] = true
      user_id = db.execute("SELECT id FROM users WHERE username=?", user)
      session[:user_id] = user_id
      db.execute('INSERT INTO users (username, pwd_digest, lvl) VALUES (?,?,?)',[user, pwd_digest, lvl])
      redirect('/hub')
    else
      p "password matchar ej"
      redirect('/register') #pwd != pwd2
    end
  else
    p "usernamn taget"
    redirect('/register') #username redan taget
  end
end

get('/login') do
  slim(:login)
end

post('/login') do
  db = getDB("db/railed.db")
  user = params["user"]
  pwd = params["pwd"]

  result = db.execute("SELECT id,pwd_digest,lvl FROM users WHERE username=?",user)

  if result.empty?
    p "Användare finnes ej"
    redirect('/login') #Fel användarnamn
  end
  puts result
  user_id = result.first["id"]
  pwd_digest = result.first["pwd_digest"]
  if BCrypt::Password.new(pwd_digest) == pwd
    p result.first["lvl"]
    if result.first["lvl"] == 1
      session[:admin] = true
    else
      session[:admin] = false
    end
    session[:logged_in] = true
    session[:user_id] = user_id
    redirect('/hub')
  else
    p "Fel lösenord"
    redirect('/login') #Fel lösenord
  end
end

post('/logout') do
  session[:logged_in] = false
  session[:admin] = false
  session[:user_id] = 0
  redirect('/hub')
end

# HUB-GETS & POSTS
get('/') do
  redirect('/login')
end

get('/hub') do
  slim(:hub)
end

#TINDERRELATERADE GETS OCH POSTS
get('/tinder') do
  db = getDB("db/railed.db")
  @id = session[:user_id]
  p @id
  @name =  db.execute("SELECT username FROM users WHERE id=?", @id).first["username"]
  slim(:tinderhub)
end

#Forumrelaterade Gets & Posts
get('/forum') do
  db = getDB("db/railed.db")
  @forumen = db.execute('SELECT * FROM forums')
  slim(:forumhub)
end

get('/forum/:id') do
  @id = params[:id]
  db = getDB("db/railed.db")
  @user_name = db.execute("SELECT username FROM users WHERE id =?", session[:user_id]).first["username"]
  @rubbe = db.execute("SELECT rubrik FROM forums WHERE id=?",@id).first["rubrik"]
  @chatten = db.execute("SELECT messages.id,username,message FROM messages LEFT JOIN users on messages.user = users.id WHERE forum = ?", @id)
  slim(:forum)
end

post('/createforum') do
  rubr = params[:rub]
  db = getDB("db/railed.db")
  db.execute("INSERT INTO forums (rubrik) VALUES (?)", rubr)
  id = db.execute("SELECT id FROM forums WHERE rubrik = ?", rubr).first["id"]
  redirect("/forum/#{id}")
end

post('/chatta/:id') do
  id = params[:id]
  mess = params[:meddelande]
  uid = session[:user_id]
  db = getDB("db/railed.db")
  db.execute('INSERT INTO messages (forum,user,message) VALUES (?,?,?)',[id,uid,mess])
  redirect("/forum/#{id}")
end

post('/radera/:fid/:id') do
  mid = params[:id]
  p mid
  db = getDB("db/railed.db")
  fid = params[:fid]
  db.execute("DELETE FROM messages WHERE id = ?",mid)
  redirect("/forum/#{fid}")
end