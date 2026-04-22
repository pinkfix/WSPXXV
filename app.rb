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

# Kollar alltid innan man öppnar en sida relaterad till forum ifall man är inloggad, och kollar isåfall admin perms.
#
# @param [Boolean] :logged_in Ifall användaren är inloggad.
# @param [Boolean] :user_id Användarens ID. Båda är från session.
# @see Model#backgroundCheck
before('/forum/*') do
  if session[:logged_in]
    session[:admin] = backgroundCheck(session[:user_id])
  end
end

# FUNKTIONER RELATERADE TILL ANVÄNDARSYSTEMET

# Visar registreringssidan.
#
get('/account/register') do
  slim(:signup)
end

# Registrerar en användare, ifall alla värden var korrekt formatterade
#
# @param [String] "user" Användarnamn
# @param [String] "pwd" Lösenordet
# @param [String] "pwd_confirm" Lösenordet, igen
# @see Model#ddosBuffer
# @see Model#validateLength
# @see Model#getUserInfo
# @see Model#sättUppAnvändare
post('/register') do
  postDefend()
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
      redirect('/lobby')
    else
      err("register","Lösenordet matchar inte!")
    end
  else
    err("register", "Någon annan använder redan namnet #{user}. Pröva med ett annat.")
  end
end

#Visar inloggningssidan
#
get('/account/login') do
  slim(:login)
end

# Loggar in en användare, ifall alla värden var korrekta.
#
# @param [String] "user" Användarnamn
# @param [String] "pwd" Lösenordet
# @see Model#ddosBuffer
# @see Model#getUserInfo
# @see Model#logIn
post('/login') do
  postDefend()
  user = params["user"]
  pwd = params["pwd"]

  ddosBuffer()

  result = getUserInfo(user)

  if result == nil
    err("login","Du har angett fel Användarnamn eller Lösenord!")
  end

  user_id = result["id"]
  pwd_digest = result["pwd_digest"]
  if passwordCheck(pwd_digest, pwd)
    logIn(result["lvl"])
    session[:user_id] = user_id
  else
    err("login","Du har angett fel Användarnamn eller Lösenord!")
  end
  redirect('/lobby')
end

# Loggar ut en användare.
#
# @see Model#resetSession
post('/logout') do
  postDefend()
  resetSession()
  redirect('/lobby')
end

# Visar upp sidan där man kan "radera" sin användare.
#
# @param [Integer] :user_id Användarens ID (tas från session)
# @see Model#tedIdInfo
get('/account/delete') do
  @username = getIdInfo(session[:user_id])["username"]
  slim(:account_delete)
end

# Raderar en användare, ifall hen skriver in sitt lösenord.
#
# @param [String] :pwd_confirm Lösenordet som användaren skriver in för att konfirmera.
# @param [Integer] :user_id Användarens ID (tas från session)
# @see Model#getIdInfo
# @see Model#eraseUser
# @see Model#resetSession
post('/account/delete') do
  postDefend()
  pwd_digest = getIdInfo(session[:user_id])["pwd_digest"]
  pwd_confirm = params[:pwd_confirm]
  if passwordCheck(pwd_digest, pwd_confirm)
    eraseUser(session[:user_id])
    resetSession()
    redirect('/lobby')
  else
    session[:error] = "Inkorrekt lösenord!"
    sleep(5)
    redirect('/account/delete')
  end
end

# HUB-GETS & POSTS
get('/') do
  redirect('/account/login')
end

get('/lobby') do
  slim(:railed_lobby)
end

#TINDERRELATERADE GETS OCH POSTS

# Detta är en testsida som används i syfte att ha en sida att hindra utloggade från att nå.
#
get('/tinder') do
  if session[:logged_in]
    @id = session[:user_id]
    @name = getIdInfo(@id)["username"]
  else
    redirect('not-found')
  end
  slim(:test)
end

#Forumrelaterade Gets & Posts

# Visar alla forum som finns i ordning från äldst till nyast, samt placerar de favoriserade över de ofavoriserade.
#
# @param [Boolean] :logged_in Om användaren är inloggad eller ej
# @see Model#getForumsFav
# @see Model#getForumsNotFav
# @see Model#getForumsAll
get('/forum/hub') do
  if session[:logged_in]
    @favforumen = getForumsFav(session[:user_id])
    @forumen = getForumsNotFav(session[:user_id])
    
  else
    @forumen = getForumsAll()
  end
  slim(:forum_all)
end

# Visar alla meddelanden från ett specifikt forum, samt vem som skrev dem.
#
# @param [Integer] :id Forumets ID
# @param [Integer] :user_id Användarens ID, från sessions (if applicable)
# @see Model#getIdInfo
# @see Model#getForumsFromId
# @see Model#getChatHistory
get('/forum/:id') do
  @id = params[:id]
  @user_name = getIdInfo(session[:user_id])
  @rubbe = getForumsFromID(@id)["rubrik"]
  @chatten = getChatHistory(@id)
  slim(:forum_distinct)
end

# Skapar ett forum som sparas i databasen, och redirectar till den.
#
# @param [String] :rub Forumets namn
# @see Model#createForum
# @see Model#getForumFromRubrik
post('/forum/create') do
  postDefend()
  rubr = params[:rub]
  createForum(rubr)
  redirect("/forum/hub")
end

#Skriver ett meddelande i ett forum, dvs sparar till messages.
#
# @param [Integer] :id Forumets ID
# @param [String] :meddelande Meddelandet
# @param [Integer] :user_id Användarens ID, från sessions.
# @see Model#insertMessages
post('/chatta/:id') do
  postDefend()
  id = params[:id]
  mess = params[:meddelande]
  uid = session[:user_id]
  insertMessage(id,uid,mess)
  redirect("/forum/#{id}")
end

# Raderar ett meddelande i ett forum, dvs tar bort från messages.
#
# @param [Integer] :forum_id Forumets ID
# @param [Integer] :id Meddelandets ID
# @see Model#deleteMessage
post('/radera/:forum_id/:id') do
  postDefend()
  id = params[:id]
  deleteMessage(id)
  forum_id = params[:forum_id]
  redirect("/forum/#{forum_id}")
end

# Favoriserar ett forum för en viss användare.
#
# @param [Integer] :forumet_id Forumets ID
# @param [Integer] :user_id Användarens ID, från session
# @see Model#favourite
post('/forum/fav') do
  postDefend()
  favourite(params[:forumet_id], session[:user_id])
  redirect('/forum/hub')
end

# Avfavoriserar ett forum för en viss användare.
#
# @param [Integer] :forumet_id Forumets ID
# @param [Integer] :user_id Användarens ID, från session
# @see Model#unfavourite
post('/forum/avfav') do
  postDefend()
  fid = params[:forumet_id]
  unfavourite(fid, session[:user_id])
  redirect('/forum/hub')
end

not_found do
  slim(:error)
end