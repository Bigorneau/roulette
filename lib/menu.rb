require "json"
require "redcarpet"
require "nokogiri"

Markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

module MenuFormater

  def self.clean(html)
    doc = Nokogiri.HTML(html)
    doc.css('a,blink,marquee,div,blockquote').each do |el|
        el.replace(el.inner_html)
    end
    cleaned = doc.to_html
    puts cleaned
    return cleaned
  end
end

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
        content: MenuFormater.clean(content)
      }.to_json

      io.write(json)
    end
  end
end

