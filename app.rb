require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

# BEFORE-BLOCK

# Definiera ett before-block som kollar om användaren är inloggad och admin
before do
 # Lista alla begränsade routes
 restricted_paths = ['/private', '/admin/*', '/settings']

 # Om användaren inte är inloggad och försöker komma åt en begränsad sökväg,
 # omdirigera dem till inloggningssidan.	Här har session[:logged_in satts till “true” vid inloggning. 
 if session[:logged_in] && restricted_paths.include?(request.path_info)   #alternativt session[:id] != nil...
   redirect '/login'
 end

 # Om användaren är inloggad men inte är en administratör och försöker komma åt en administratörssökväg,
 # omdirigera dem till startsidan. Här har session[:admin] satts till “true” vid inloggningen.
 if session[:logged_in] && !session[:admin] && request.path_info == '/admin'
   redirect '/'
 end
end



# DRY-Funktioner



#Helper functions

def getDB(database)
  db = SQLite3::Database.new(database)
  db.results_as_hash = true
  return db
end


# FUNKTIONER RELATERADE TILL ANVÄNDARSYSTEMET

get('/register') do
  slim(:register)
end

post('/register') do
  db = getDB("db/railed.db")
  user = params["user"]
  pwd = params["pwd"]
  pwd_confirm = params["pwd_confirm"]
  lvl = params["admin"]
  
  result = db.execute("SELECT id FROM user WHERE username=?",user)

  if result.empty?
    if pwd == pwd_confirm
      pwd_digest = BCrypt::Password.create(pwd)
      db.execute("INSERT INTO users(username, pwd_digest, lvl) VALUES (?,?,?)",[user,pwd_digest, lvl])
      if lvl
        session[:admin] = true
      end
      session[:logged_in] = true
      user_id = db.execute("SELECT id FROM users WHERE username=?", user)
      session[:user_id] = user_id
      redirect('/hub')
    else
      redirect('/register') #pwd != pwd2
    end
  else
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
    redirect('/login') #Fel användarnamn
  end
  puts result
  user_id = result.first["id"]
  pwd_digest = result.first["pwd_digest"]
  if BCrypt::Password.new(pwd_digest) == pwd
    if result.first["lvl"]
      session[:admin] = true
    end
    session[:logged_in] = true
    session[:user_id] = user_id
    redirect('/hub')
  else
    redirect('/login') #Fel lösenord
  end
end

# HUB-GETS & POSTS
get('/') do
  redirect('/login')
end

get('/hub') do
  slim(:hub)
end

# HÄR BÖRJAR TINDERRELATERADE GETS OCH POSTS
get('/tinder') do
  db = getDB("db/railed.db")
  @id = session[:user_id]
  @name =  db.execute("SELECT username FROM users WHERE id=?", @id).first["username"]
  slim(:tinder)
end
