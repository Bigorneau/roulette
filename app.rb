require "json"
require "time"

require "rubygems"
require "bundler/setup"

require "sinatra"
require "sinatra/cookies"
require "sinatra/reloader" if development?
require "slim"

require "./lib/menu"
require "./lib/orders"
require "./lib/users"

set :bind, '0.0.0.0'

before do
  @orders = Orders.fetch
  @users = Users.fetch
end

get "/" do
  slim :index
end

get "/apropos" do
  slim :apropos
end

post "/order" do
  redirect to("/?error") if Orders.empty?(params)
  redirect to("/?invalid_user") unless Users.authorized?(params[:user])

  if params[:like] && !params[:like].empty?
    if Orders.exist?(params[:like])
      order = Orders.for(params[:like]).first
      Orders.place(params[:user], order["content"], OrderPriority::RANDOM)
    else
      redirect to("/?invalid_user")
    end
  else
    orders = params[:content].split(/\r?\n--+\r?\n/).map(&:strip)
    priority = params[:priority] ? params[:priority] : OrderPriority::RANDOM
    if orders.length > 1
      Orders.place(params[:user], *orders, OrderPriority::SACRIFICE)
    else
      Orders.place(params[:user], *orders, priority)
    end
  end

  cookies[:user] = params[:user]
  redirect to("/?thankyou")
end

__END__

@@ layout
doctype html
html
  head
    title ddproulette
    link(rel="stylesheet" href="http://fonts.googleapis.com/css?family=Fugaz+One")
    link(rel="stylesheet" href="http://fonts.googleapis.com/css?family=Noto+Sans:400,400italic,700,700italic")
    link(rel="stylesheet" href="/css/normalize.css")
    link(rel="stylesheet" href="/css/application.css")

  body
    header
      h1
        a(href="/") <span>ddp</span>roulette
        | &nbsp;🔫


    - if File.exist?("db/order_sent")
        section.message.error La commande pour aujourd'hui est déjà passée !
    - if params.key?("error")
        section.message.error Il faut tout remplir
    - if params.key?("exist")
        section.message.error Déjà commandé !
    - if params.key?("invalid_user")
        section.message.error Utilisateur invalide
    - if params.key?("thankyou")
        section.message.notice Commande passée !

    section
      == yield

    footer
      a(href="/apropos" title="C'est quoi ?") ?

@@ apropos
section.solo
  strong ddproulette
  |  est un service pour automatiser la sélection de la personne qui doit
    commander chez Délice des Pâtes.

  iframe(src="http://n393160.shoutem.com/v4/?builderPreview=true&design_mode=true#dsParams[nodeId]=4300656&_=GenericScreen&page=ListPage%3AContentMenuItem%3A000000000004300656")

@@ index
.content-main
  h2 Ma commande :
  form(action="/order" method="post")
    p
      input(type="text" name="user" placeholder="Utilisateur LDAP" value="#{cookies[:user] || nil}")
    p
      textarea(name="content" placeholder="Plat, boisson, dessert, chacun sur une ligne" rows="5")
    p
      select(name="like")
        option(value="") Je veux commander comme…
        - @orders.each do |order|
          - order_username = order["user"]
          - order_user = @users[order_username]
          option(value="#{order_username}") #{order_user["firstname"]} #{order_user["lastname"]}
    p
      input{type="radio" name="priority" value="#{OrderPriority::RANDOM}" checked="checked"} Aléatoire
    p
      input{type="radio" name="priority" value="#{OrderPriority::SACRIFICE}"} Je me sacrifie aujourd'hui
    p
      input{type="radio" name="priority" value="#{OrderPriority::DODGE}"} Je ne peux pas commander aujourd'hui
    p
      input(type="submit" name="send" value="Commander")
  h2
    - if @orders.count.zero?
      | Personne ne commande pour l'instant !
    - elsif @orders.count == 1
      | Une personne commande ce midi.
    - else
      | #{@orders.count} personnes commandent ce midi.
  ul.orders
      - @orders.each do |order|
        - order_user = @users[order["user"]]
        li
          h3 #{order_user["firstname"]} #{order_user["lastname"]}
          p== order["content"].gsub(/\r?\n/, "<br />")

.content-more
  h2 Au menu ce midi :
  .menu
    - if Menu.available?
      == Menu.content
    - else
      | On sait pas encore !
