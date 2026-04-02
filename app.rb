require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require 'time'
require_relative './model.rb'

enable :sessions

include Model

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
  user = params["user"]
  pwd = params["pwd"]
  pwd_confirm = params["pwd_confirm"]

  ddosBuffer()

  validateLength(user, pwd)

  if params["admin"]
    session[:admin] = 1
  else
    session[:admin] = 0
  end

  result = getUserInfo(user)

  if result == nil
    if pwd == pwd_confirm
      sättUppAnvändare(user, pwd, session[:admin])
      redirect('/hub')
    else
      error("register","Lösenordet matchar inte!")
    end
  else
    error("register", "Någon annan använder redan namnet #{user}. Pröva med ett annat.")
  end
end

get('/account/login') do
  slim(:login)
end

post('/login') do
  db = getDB("db/railed.db")
  user = params["user"]
  pwd = params["pwd"]

  ddosBuffer()

  result = getUserInfo(user)

  if result == nil
    error("login","Du har angett fel Användarnamn eller Lösenord!")
  end

  puts result
  user_id = result["id"]
  pwd_digest = result["pwd_digest"]
  if BCrypt::Password.new(pwd_digest) == pwd
    logIn(result["lvl"])
    session[:user_id] = user_id
    redirect('/hub')
  else
    error("login","Du har angett fel Användarnamn eller Lösenord!")
  end
end

post('/logout') do
  resetSession()
  redirect('/hub')
end

get('/account/delete') do
  @username = getIdInfo(session[:user_id])["username"]
  p @username
  slim(:accdelete)
end

post('/accdelete') do
  pwd_digest = getIdInfo(session[:user_id])["pwd_digest"]
  pwd_confirm = params[:pwd_confirm]
  if BCrypt::Password.new(pwd_digest) == pwd_confirm
    eraseUser(session[:user_id])
    resetSession()
    redirect('/hub')
  else
    error("delete", "Inkorrekt lösenord!")
    sleep(2)
  end
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
  @name = getIdInfo(@id)["username"]
  slim(:tinderhub)
end

#Forumrelaterade Gets & Posts
get('/forum/hub') do
  if session[:logged_in]
    @favforumen = getForumsFav(session[:user_id])
    @forumen = getForumsNotFav(session[:user_id])
    
  else
    @forumen = getForumsAll()
  end
  slim(:forumhub)
end

get('/forum/:id') do
  @id = params[:id]
  @user_name = getIdInfo(session[:user_id])
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
  redirect("/forum/#{forum_id}")
end

post('/forum/fav') do
  favourite(params[:forumet_id], session[:user_id])
  redirect('/forum/hub')
end

post('/forum/avfav') do
  fid = params[:forumet_id]
  p session[:user_id]
  p fid
  unfavourite(fid, session[:user_id])
  redirect('/forum/hub')
end