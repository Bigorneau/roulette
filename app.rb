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

before do
  @orders = Orders.fetch
end

get "/" do
  slim :index
end

get "/apropos" do
  slim :apropos
end

post "/order" do
  order = Order.new(params[:user], params[:content])

  redirect to("/?error") if Orders.empty?(params)
  redirect to("/?invalid_user") unless Users.authorized?(order.user)
  redirect to("/?exist") if Orders.exist?(params[:user]) # TODO: overwrite the previous order

  Orders.place(params[:user], params[:content])
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
        a(href="#{url("/")}") <span>ddp</span>roulette
        | &nbsp;🔫


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
      a(href="#{url("/apropos")}" title="C'est quoi ?") ?

@@ apropos
section.solo
  strong ddproulette
  |  est un service pour automatiser la sélection de la personne qui doit
    commander chez Délice des Pâtes.

@@ index
.content-main
  h2 Ma commande :
  form(action="#{url("/order")}" method="post")
    p
      input(type="text" name="user" placeholder="Utilisateur LDAP" value="#{cookies[:user] || nil}")
    p
      textarea(name="content" placeholder="Commande" rows="5")
    p
      input(type="submit" name="send" value="Commander")
  h2
    - if @orders.count.zero?
      | Personne ne commande pour l'instant !
    - elsif @orders.count == 1
      | Une personne commande ce midi.
    - else
      | #{@orders.count} personnes commandent ce midi.

.content-more
  h2 Au menu ce midi :
  .menu
    - if Menu.available?
      == Menu.content
    - else
      | On sait pas encore !
