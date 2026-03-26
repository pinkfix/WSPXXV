require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

# BEFORE-BLOCK

before('/forum/*') do
  if session[:logged_in]
    session[:admin] = backgroundCheck(session[:user_id])
  end
end

# FUNKTIONER RELATERADE TILL ANVÄNDARSYSTEMET

get('/account/register') do
  slim(:signup)
end

post('/register') do
  db = getDB("db/railed.db")
  user = params["user"]
  pwd = params["pwd"]
  pwd_confirm = params["pwd_confirm"]
  if params["admin"]
    session[:admin] = 1
  else
    session[:admin] = 0
  end
  result = getUserInfo(user)
  if result.empty?
    if pwd == pwd_confirm
      sättUppAnvändare(user, pwd_digest, session[:admin])
      redirect('/hub')
    else
      session[:error] = "Lösenordet matchar inte!"
      redirect('/account/register')
    end
  else
    session[:error] = "Någon annan använder redan namnet #{user}. Pröva med ett annat."
    redirect('/account/register')
  end
end

get('/account/login') do
  slim(:login)
end

post('/login') do
  db = getDB("db/railed.db")
  user = params["user"]
  pwd = params["pwd"]

  result = getUserInfo(user)

  if result.empty?
    session[:error] = "Du har angett fel ANvändarnamn eller Lösenord!"
    redirect('/account/login')
  end

  puts result
  user_id = result["id"]
  pwd_digest = result["pwd_digest"]
  if BCrypt::Password.new(pwd_digest) == pwd
    p "Yo this shit TRU A1§F"
    logIn(result["lvl"])
    session[:user_id] = user_id
    redirect('/hub')
  else
    session[:error] = "Du har angett fel Användarnamn eller Lösenord!"
    redirect('/account/login')
  end
end

post('/logout') do
  resetSession()
  redirect('/hub')
end

# HUB-GETS & POSTS
get('/') do
  redirect('/account/login')
end

get('/hub') do
  slim(:hub)
end

#TINDERRELATERADE GETS OCH POSTS
get('/tinder') do
  db = getDB("db/railed.db")
  @id = session[:user_id]
  p @id
  @name = getIdInfo(@id)["username"]
  slim(:tinderhub)
end

#Forumrelaterade Gets & Posts
get('/forum/hub') do
  db = getDB("db/railed.db")
  @forumen = db.execute('SELECT * FROM forums')
  slim(:forumhub)
end

get('/forum/:id') do
  @id = params[:id]
  @user_name = getIdInfo(session[:user_id])["username"]
  @rubbe = getForumsFromID(@id)["rubrik"]
  @chatten = getChatHistory(@id)
  slim(:forum)
end

post('/forum/create') do
  rubr = params[:rub]
  createForum(rubr)
  id = getForumFromRubrik(rubr)["id"]
  redirect("/forum/#{id}")
end

post('/chatta/:id') do
  id = params[:id]
  mess = params[:meddelande]
  uid = session[:user_id]
  insertMessage(id,uid,mess)
  redirect("/forum/#{id}")
end

post('/radera/:forum_id/:id') do
  id = params[:id]
  deleteMessage(id)
  forum_id = params[:forum_id]
  redirect("/forum/#{fid}")
end

gets('/account/delete') do
  @username = getIdInfo(session[:user_id])["username"]
  slim(:accDelete)
end

post('/account/delete') do
  eraseUser(session[:user_id])
  resetSession()
  redirect('/hub')
end