require "json"

module Users
  DB_FILE = "db/users.json"

  def self.fetch
    @users = JSON.load(File.read(DB_FILE)) || {}
  rescue
    @users = {}
  end

  def self.authorized?(user)
    fetch
    @users.key?(user)
  end

end

