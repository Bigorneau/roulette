require "json"
require "time"
require "ostruct"

require "rubygems"
require "bundler/setup"

require "gmail"

config = JSON.load(File.read("config.json"))

GMAIL_USER = config["gmail"]["user"]
GMAIL_PASSWORD = config["gmail"]["password"]

DAY_NAMES = %w(LUNDI MARDI MERCREDI JEUDI VENDREDI SAMEDI DIMANCHE)

def error(message)
  $stderr.puts message
  exit 1
end

task :fetch_daily_menu do
  require "./lib/menu"

  if Menu.available?
    error "Le menu d'aujourd'hui est déjà disponible"
  end

  puts "Récupération du menu d'aujourd'hui..."

  today = Date.today
  day = "%02d" % today.day
  week_day = DAY_NAMES[today.wday - 1]

  Gmail.new(GMAIL_USER, GMAIL_PASSWORD) do |gmail|
    todays_menu = gmail.inbox.emails(on: today).detect do |email|
      p email.subject
      email.subject =~ /MENU DELICE DES PATES DU #{week_day} #{day}/
    end

    if todays_menu
      text_part = todays_menu.parts.detect { |p| p.content_type =~ /text\/plain/ }
      menu_text = text_part.decoded.delete('*').strip

      Menu.store(today, menu_text)
      puts "Menu pour le #{today}"
      puts menu_text
    else
      error "[erreur] Le menu d'aujourd'hui n'est pas encore disponible"
    end
  end
end

task :roulette do
  require "./lib/orders"
  require "./lib/scores"

  puts "ROULETTE TIME!"

  orders = Orders.fetch
  scores = Scores.fetch

  if orders.empty?
    error "Pas de commande"
  end

  order_candidates = orders.map { |o| o["user"] }

  # TODO: Find a fair way to compute the victim
  # min_score = scores.values_at(*order_candidates).min
  # score_candidates = scores.select { |_, v| v.nil? || v == min_score }.keys
  #
  # p [orders, scores]

  roulette_candidates = order_candidates

  puts "Candidats: #{roulette_candidates}"
  victim = roulette_candidates.sample
  puts "=> #{victim}"

  Gmail.new(GMAIL_USER, GMAIL_PASSWORD) do |gmail|
    # Email the victim
    gmail.deliver do
      to "#{victim}@wyplay.com"
      subject "[DDP] BANG ! C'est ton tour de commander !"
      text_part do
        intro = %Q{
          Salut, c'est ton tour de commander !

          #{orders.count} personnes ont commandé aujourd'hui :
          #
        }.gsub(/^\s*/, "")
        orders_text = orders.map do |order|
          %Q{
          # #{order["user"]}
          #{order["content"]}

          }.gsub(/^\s*/, "")
        end.join("\n")

        body(intro + orders_text)
      end
    end # 1st email

    survivors = order_candidates - [victim]

    # Email the others
    gmail.deliver do
      to survivors.map { |s| "#{s}@wyplay.com" }.join(", ")
      subject "[DDP] C'est #{victim} qui commande"
      text_part do
        body %Q{
          Salut, c'est #{victim} qui commande aujourdhui !

          Merci de lui amener de quoi régler le livreur.
        }.gsub(/^\s*/, "")
      end
    end # 2nd email

  end
end
