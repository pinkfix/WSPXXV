module Model
  # Links variable to a Database for easy use of the .execute()-function.
  #
  # @param [String] database href to the database.
  #
  # @return [Function] a function calling on the Database.
  def getDB(database)
    db = SQLite3::Database.new(database)
    db.results_as_hash = true
    return db
  end

  # Verifies that the person inserted is an admin.
  #
  # @param [integer] user_id The ID of the user
  #
  # @return [true] If user is admin
  # @return [false] If user is not admin
  def backgroundCheck(user_id)
    db = getDB("db/railed.db")
    if db.execute("SELECT lvl FROM users WHERE id=?",user_id).first["lvl"] == 1
      return true
    end
    return false
  end

  # DRY-function saving the reason for error and then throwing the user back to the appropriate site.
  #
  # @param [String] rld Which of the error sites to redirect to.
  # @param [String] error_message The error message
  #
  # @return [String] error message and redirect to appropriate site.
  def err(rld, error_message)
    session[:error] = error_message
    redirect("/account/#{rld}")
  end

  # validates the length of the usernamne and password(and if the password is only numbers) when registering.
  #
  # @param [String] username Username
  # @param [String] password The Password
  def validateLength(username, password)
    if username.length < 3
      err("register","För kort användarnamn. Måste vara mellan 3 och 30 karaktärer")
    elsif username.length > 30
      err("register","För långt användarnamn. Måste vara mellan 3 och 30 karaktärer")
    end
    if password.to_i == password
      err("register","Lösenord får ej bestå av endast siffror!")
    elsif password.length < 8
      err("register","För kort lösenord. Måste vara mellan 8 och 40 karaktärer")
    elsif password.length > 40
      err("register","För långt lösenord. Måste vara mellan 8 och 40 karaktärer")
    end
  end

  # Sätter upp alla viktiga variabler för en inloggad användare, samt sätter in dessa i databasen
  #
  # @param [String] user Username
  # @param [String] pwd Password
  # @param [Boolean] lvl Admin status
  def sättUppAnvändare(user, pwd, lvl)
    db = getDB("db/railed.db")
    pwd_digest = BCrypt::Password.create(pwd)
    session[:logged_in] = true
    user_id = db.execute("SELECT * FROM users").length + 1
    session[:user_id] = user_id
    session[:error] = "W"
    db.execute('INSERT INTO users (username, pwd_digest, lvl) VALUES (?,?,?)',[user, pwd_digest,lvl])
  end

  # Hämtar all sparad info från användaren med ett specifikt ID.
  #
  # @param [Integer] id Användarens ID
  #
  # @return [Hash]
  #   :id [Integer] Användarens ID
  #   :username [String] Användarens namn
  #   :pwd_digest [String] Andvändarens krypterade lösenord.
  #   :lvl [Boolean] Om användaren är en Admin eller ej.
  def getIdInfo(id)
    db = getDB("db/railed.db")
    return db.execute("SELECT * FROM users WHERE id=?",id).first
  end

  # Hämtar all sparad info från användaren med ett specifikt namn.
  #
  # @param [String] user Användarens namn
  #
  # @return [Hash]
  #   :id [Integer] Användarens ID
  #   :username [String] Användarens namn
  #   :pwd_digest [String] Andvändarens krypterade lösenord.
  #   :lvl [Boolean] Om användaren är en Admin eller ej.
  def getUserInfo(user)
    db = getDB("db/railed.db")
    return db.execute("SELECT * FROM users WHERE username=?",user).first
  end

  # Sätter session-variablerna :admin och :logged_in efter en lyckad inloggning.
  #
  # @param [Boolean] admin Ifall personen är admin
  def logIn(admin)
    if admin == 1
      session[:admin] = true
    else
      session[:admin] = false
    end
    session[:logged_in] = true
  end

  # Hämtar rubriken info från forumet med ett specifikt ID.
  #
  # @param [Integer] id Forumets ID
  #
  # @return [Hash]
  #   :rubrik [String] Forumets namn
  def getForumsFromID(id)
    db = getDB("db/railed.db")
    return db.execute("SELECT rubrik FROM forums WHERE id=?",@id).first
  end

  # Hämtar all relevant info från meddelanden i ett specifikt forum
  #
  # @param [Integer] id Forumets ID
  #
  # @return [Hash]
  #   :id [Integer] meddelandets ID
  #   :username [String] Användaren som skrev meddelandet
  #   :message [String] Meddelandet
  def getChatHistory(id)
    db = getDB("db/railed.db")
    return db.execute("SELECT messages.id,username,message FROM messages LEFT JOIN users on messages.user = users.id WHERE forum = ?", @id)
  end

  # Skapar ett forum i databastabellen forums
  #
  # @param [String] forum_name Forumets namn
  def createForum(forum_name)
    db = getDB("db/railed.db")
    db.execute("INSERT INTO forums (rubrik) VALUES (?)", forum_name)
  end

  # Hämtar all info från forumet med ett specifikt namn.
  #
  # @param [String] forum_name Forumets rubrik
  #
  # @return [Hash]
  #   :id [Integer] Forumets ID
  #   :rubrik [String] Forumets namn
  def getForumFromRubrik(forum_name)
    db = getDB("db/railed.db")
    return db.execute("SELECT * FROM forums WHERE rubrik = ?", rubr).first
  end

  # Lägger in ett meddelande i databasen.
  #
  # @param [Integer] forum Forumets ID
  # @param [Integer] user Användarens ID
  # @param [String] message Meddelandet som ska publiceras.
  def insertMessage(forum, user, message)
    db = getDB("db/railed.db")
    db.execute('INSERT INTO messages (forum,user,message) VALUES (?,?,?)',[forum, user, message])
  end

  # Raderar ett meddelande.
  #
  # @param [Integer] id Meddelandets ID
  def deleteMessage(id)
    db = getDB("db/railed.db")
    db.execute("DELETE FROM messages WHERE id = ?",id)
  end

  # Nollställer samtliga variabler i session.
  #
  def resetSession()
    session[:logged_in] = false
    session[:admin] = false
    session[:user_id] = 0
  end

  # Raderar en användare. DISCLAIMER: Raderar den faktiskt inte! Ersätter istället namnet med Deleted User och det krypterade lösenordet med Namnet(for admin puropses).
  #
  # @param [Integer] user_id Användarens ID
  # @see Model#getIDInfo
  def eraseUser(user_id)
    db = getDB("db/railed.db")
    name = getIdInfo(user_id)["username"]
    db.execute("UPDATE users SET username='Deleted User',pwd_digest=? WHERE id=?", [name, user_id])
  end

  # Pausar programmet i 3 sekunder ifall någon specifik person försökt att logga in mindre än 3 sekunder efter sitt tidigare försök.
  #
  def ddosBuffer()
    if session[:time]
      time = Time.now
      if time - session[:time] < 3
        sleep(3)
      end
    end
    session[:time] = Time.now
  end

  # hämtar alla forum som en användare har gillat.
  #
  # @param [Integer] userid Användarens ID.
  #
  # @return [Hash]
  #   :id [Integer] Forumets ID
  #   :rubrik [String] Forumets namn
  #   :forum_id [Integer] Forumets ID (Från relationstabellen), samma som den första.
  #   :user_id [Integer] Användarens ID (Från relationstabellen)
  def getForumsFav(userid)
    db = getDB("db/railed.db")
    everything = db.execute('SELECT * FROM forums INNER JOIN favoriter ON forums.id = favoriter.forum_id WHERE favoriter.user_id = ?', userid)
    p everything
    return everything
  end

  # hämtar alla forum som en användare INTE har gillat.
  #
  # @param [Integer] userid Användarens ID.
  #
  # @return [Hash]
  #   :id [Integer] Forumets ID
  #   :rubrik [String] Forumets namn
  #   :forum_id [Integer] Forumets ID (Från relationstabellen), samma som den första.
  #   :user_id [Integer] Användarens ID (Från relationstabellen)
  def getForumsNotFav(userid)
    db = getDB("db/railed.db")
    everything = db.execute('SELECT * FROM forums WHERE rubrik NOT IN (SELECT rubrik FROM forums INNER JOIN favoriter ON forums.id = favoriter.forum_id WHERE favoriter.user_id = ?)', userid)
    return everything
  end

  # hämtar alla forum (används när användaren inte är inloggad och därför inte har något ID).
  #
  # @return [Hash]
  #   :id [Integer] Forumets ID
  #   :rubrik [String] Forumets namn
  #   :forum_id [Integer] Forumets ID (Från relationstabellen), samma som den första.
  #   :user_id [Integer] Användarens ID (Från relationstabellen)
  def getForumsAll()
    db = getDB("db/railed.db")
    everything = db.execute('SELECT * FROM forums')
    return everything
  end

  # Lägger till en koppling i relationstabellen favoriter.
  #
  # @param [Integer] f_id Forumets ID
  # @param [Integer] u_id Användarens ID
  def favourite(f_id, u_id)
    db = getDB("db/railed.db")
    db.execute("INSERT INTO favoriter (forum_id, user_id) VALUES (?,?)",[f_id,u_id])
  end

  # Tar bort en koppling i relationstabellen favoriter.
  #
  # @param [Integer] f_id Forumets ID
  # @param [Integer] u_id Användarens ID
  def unfavourite(f_id, u_id)
    db = getDB("db/railed.db")
    db.execute("DELETE FROM favoriter WHERE forum_id=? AND user_id=?",[f_id,u_id])
  end
end