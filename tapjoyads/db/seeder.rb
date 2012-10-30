class Seeder

  class_attribute :all

  def self.run!
    all.each(&:run!)
  end

  def self.inherited(subclass)
    self.all ||= Set.new
    self.all << subclass
  end
end

Dir["#{Rails.root}/db/seeder/*.rb"].each {|f| require f}

