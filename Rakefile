require "json"
require "time"
require "ostruct"
require "fileutils"

require "rubygems"
require "bundler/setup"

require "gmail"
require "uri"
require "cgi"

config = JSON.load(File.read("config.json"))

GMAIL_USER = config["gmail"]["user"]
GMAIL_PASSWORD = config["gmail"]["password"]

SENDER = config["service"]["sender"]

HOSTNAME = config["host"]["url"]

ORDER_SENT_FILE = File.expand_path("./db/order_sent", File.dirname(__FILE__))
ORDERS_FILE = File.expand_path("./db/orders.json", File.dirname(__FILE__))

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

  Gmail.new(GMAIL_USER, GMAIL_PASSWORD) do |gmail|
    todays_menu = gmail.inbox.emails(on: today, from: SENDER).sort_by(&:date).pop

    if todays_menu
      html_part = todays_menu.parts
        .detect { |p| p.content_type =~ /text\/html/ }
      menu_text = todays_menu.parts
        .detect { |p| p.content_type =~ /text\/plain/ }

      FileUtils.rm(ORDER_SENT_FILE) rescue puts "[warn] No confirmation to delete"
      Menu.store(today, html_part.decoded)
      puts "Menu pour le #{today}"

      gmail.deliver do
        to users.keys.map { |s| "#{s}@wyplay.com" }.join(", ")
        subject "[DDP] La roulette est chargée!"
        text_part do
          body %Q{
            Salut, le menu est à jour et vous pouvez noter vos commandes.

            Rendez-vous sur #{HOSTNAME}
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
  require "./lib/users"
  require "./lib/victim"

  puts "ROULETTE TIME!"

  orders = Orders.fetch
  users  = Users.fetch

  if orders.empty?
    error "Pas de commande"
  end
  if File.exist?(ORDER_SENT_FILE)
    error "Roulette déjà tirée!"
  end

  # Filter by priority
  priorities = Hash[orders.map {|o| [o, Integer(o["priority"]) ]}]
  puts "Priorities: #{priorities}"
  filtered = orders.select { |k| priorities[k] == priorities.values.max}
  puts "Filtered: #{filtered}"
  roulette_players = orders.map { |o| o["user"] }.sort
  roulette_candidates = filtered.map { |o| o["user"] }.sort

  puts "Players: #{roulette_players}"
  puts "Candidats: #{roulette_candidates}"
  victim = Victim.choose(roulette_candidates)
  puts "=> #{victim}"

  survivors = roulette_players - [victim]

  #----

  order_text = %Q{Bonjour,

    Nous souhaitons commander #{orders.length} menus pour 12h00 :

    --
  }.gsub(/^ */, "")

  order_text += orders.map do |order|
    order["content"].gsub(/^ */, "")
  end.join("\n--\n")

  order_text += %Q{
    --

    La commande est à adresser à #{users[victim]["firstname"]} à Wyplay à Allauch
    N° de téléphone : #{users[victim]["mobile"]}

    Pouvez-vous confirmer la réception de la commande ?

    Cordialement,
    #{users[victim]["firstname"]}
  }.gsub(/^ */, "")

  victim_intro = %Q{
    Salut, c'est ton tour de commander !

    Les personnes suivantes doivent t'amener de quoi payer :
    #{survivors.map{ |s| ["-", users[s]["firstname"], users[s]["lastname"]].join(" ") }.join(?\n)}

    Voici le %s à envoyer à delicedepates@gmail.com :
    ----
    }.gsub(/^ */, "")

  #----

  survivor_addresses = survivors.map { |s| "#{s}@wyplay.com" }.join(",")

  Gmail.new(GMAIL_USER, GMAIL_PASSWORD) do |gmail|
    # Email the victim
    gmail.deliver do
      to "#{victim}@wyplay.com"
      subject "[DDP] BANG ! C'est ton tour de commander !"

      text_part do
        body((victim_intro % 'message') + order_text)
      end

      html_part do
        mail_uri = URI::MailTo.build([
          'delicedepates@gmail.com',
          [
            ['subject', 'Commande pour Wyplay!'.gsub(/ /, '%20')],
            ['bcc', survivor_addresses],
            ['body', CGI::escape(order_text).gsub(/ /, '%20')]
          ]
        ]).to_s.gsub(/\+/, '%20')

        html_body = (victim_intro % %Q{<a href="#{mail_uri}">message</a>}) + order_text
        html_body = html_body.gsub(/$/, '<br>')

        body('<html><head></head><body>' + html_body + '</body></html>')
      end
    end # 1st email

    # Email the others if there are some
    exit if survivors.empty?
    gmail.deliver do
      to survivor_addresses
      subject "[DDP] C'est #{users[victim]["firstname"]} qui commande"
      text_part do
        body %Q{
          Salut, c'est #{users[victim]["firstname"]} #{users[victim]["lastname"]} qui commande aujourdhui !

          Merci de lui amener de quoi régler le livreur.
        }.gsub(/^ */, "")
      end
    end # 2nd email

  end

  FileUtils.touch(ORDER_SENT_FILE)
  FileUtils.rm(ORDERS_FILE) rescue puts "[warn] No previous orders"
end
