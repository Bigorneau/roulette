require "json"

module Scores
  DB_FILE = "db/scores.json"

  def self.fetch
    JSON.load(File.read(DB_FILE)) || {}
  rescue
    {}
  end

  def self.increment(*users)
    scores = fetch
    users.each do |user|
      new_score = scores.fetch(user, 0) + 1
      scores.update(user => new_score)
    end

    File.open(DB_FILE, "w+") do |io|
      io.write(JSON.dump(scores))
    end
  end
end
