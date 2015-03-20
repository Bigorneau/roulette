require "json"

module Victim

  class Chooser
    def init
      if @db_file
        if File.exist?(@db_file)
          @db = JSON.load(File.read(@db_file)) || {}
        else
          @db = {}
        end
      end
      @victim = nil
    end

    def choose(candidates)
    end

    def finish
      if @db_file
        File.open(@db_file, "w+") do |io|
          io.write(@db.to_json)
        end
      end
    end
  end

  class RandomChooser < Chooser
    def choose(candidates)
      candidates.sample
    end
  end

  class FairChooser < Chooser
    def initialize
      @db_file = "db/fair_chooser.json"
    end

    def last
      @db["last"] || nil
    end

    def choose(candidates)
      victim = (candidates - [last()]).sample || candidates.sample
      @db = {last: victim} if victim
      victim
    end
  end

  def self.choose(candidates)
    chooser = FairChooser.new
    #chooser = RandomChooser.new
    chooser.init
    victim = chooser.choose(candidates)
    chooser.finish
    victim
  end

end

