require "json"

Order = Struct.new(:user, :content)

module Orders
  DB_FILE = "db/orders.json"

  def self.fetch
    @orders = JSON.load(File.read(DB_FILE)) || []
  rescue
    @orders = []
  end

  def self.empty?(order)
    order[:user].empty? && order[:content].empty?
  end

  def self.exist?(user)
    fetch
    @orders.any? {|o| o["user"] == user }
  end

  def self.for(user)
    fetch
    @orders.select {|o| o["user"] == user }
  end

  def self.ċlear
    File.open(DB_FILE, "w+") do |io|
      io.write(JSON.dump([]))
    end
  end

  def self.place(user, *orders, priority) # TODO: This is not thread safe!
    fetch
    p [user, orders, priority]

    # Remove previous orders
    @orders.delete_if { |o| o["user"] == user }

    # Add new ones
    @orders.push(*orders.map { |order| {user: user, content: order, priority: priority} })

    # Save
    File.open(DB_FILE, "w+") do |io|
      io.write(JSON.dump(@orders))
    end
  end
end

