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
  require "./lib/users"

  puts "Récupération du menu d'aujourd'hui..."

  users = Users.fetch
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
      menu_text = text_part.decoded
                           .delete('*')
                           .gsub(" ", " ")
                           .squeeze(" ")
                           .lines.map(&:strip).join("\n")
                           .gsub(/^\s*-/, "-")
                           .gsub(/^-(\w)/) {|m| "- #{m[1].upcase}" }
                           .gsub(/:\s*$/, ":\n\n")

      Menu.store(today, menu_text)
      puts "Menu pour le #{today}"
      puts menu_text

      gmail.deliver do
        to users.keys.map { |s| "#{s}@wyplay.com" }.join(", ")
        subject "[DDP] La roulette est chargée!"
        text_part do
          body %Q{
            Salut, le menu est à jour et vous pouvez noter vos commandes.

            Rendez-vous sur http://ddproulette.wyplay.int/
          }.gsub(/^ */, "")
        end
      end # Warning mail
    else
      error "[erreur] Le menu d'aujourd'hui n'est pas encore disponible"
    end
  end
end

task :roulette do
  require "./lib/orders"
  require "./lib/scores"
  require "./lib/users"

  puts "ROULETTE TIME!"

  orders = Orders.fetch
  scores = Scores.fetch
  users  = Users.fetch

  if orders.empty?
    error "Pas de commande"
  end

  order_candidates = orders.map { |o| o["user"] }

  puts "Candidats: #{roulette_candidates}"
  victim = roulette_candidates.sample
  puts "=> #{victim}"

  survivors = order_candidates - [victim]

  Gmail.new(GMAIL_USER, GMAIL_PASSWORD) do |gmail|
    # Email the victim
    gmail.deliver do
      to "#{victim}@wyplay.com"
      subject "[DDP] BANG ! C'est ton tour de commander !"
      text_part do
        intro = %Q{
          Salut, c'est ton tour de commander !

          Les personnes suivantes doivent t'amener de quoi payer :
          #{survivors.map{ |s| "- " + users[s]["firstname"] }.join(?\n)}

          Voici le message à envoyer à delicedepates@gmail.com :
          ----
          Bonjour,

          Nous souhaitons commander #{orders.length} menus pour 12h00 :

          --
        }.gsub(/^ */, "")
        orders_text = orders.map do |order|
          %Q{
          #{order["content"]}
          }.gsub(/^ */, "")
        end.join("--\n")
        outro = %Q{
          La commande est à adresser à #{users[victim]["firstname"]} à WYPLAY (Allauch)

          N° de téléphone : #{users[victim]["phone"]}

          Pouvez-vous confirmer la réception de la commande ?

          Bien cordialement,

          --
          #{users[victim]["firstname"]}
        }

        body(intro + orders_text + outro)
      end
    end # 1st email

    # Email the others if there are some
    exit if survivors.empty?
    gmail.deliver do
      to survivors.map { |s| "#{s}@wyplay.com" }.join(", ")
      subject "[DDP] C'est #{users[victim]["firstname"]} qui commande"
      text_part do
        body %Q{
          Salut, c'est #{users[victim]["firstname"]} qui commande aujourdhui !

          Merci de lui amener de quoi régler le livreur.
        }.gsub(/^ */, "")
      end
    end # 2nd email

  end
end
