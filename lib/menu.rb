require "json"
require "redcarpet"

Markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

module Menu
  DB_FILE = "db/menu.json"

  def self.available?
    return false unless File.exist?(DB_FILE)
    menu = JSON.load(File.read(DB_FILE)) || {}

    menu["date"] == Date.today.to_s
  end

  def self.content
    menu = JSON.load(File.read(DB_FILE))

    menu["content"]
  end

  def self.store(date, content)
    File.open(DB_FILE, "w+") do |io|
      json = {
        date: date.strftime("%Y-%m-%d"),
        content: content
      }.to_json

      io.write(json)
    end
  end
end

