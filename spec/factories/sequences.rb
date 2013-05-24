class Array
  def sample
    self[rand(self.size)]
  end

  def mod(i)
    self[i % self.size]
  end
end

HEX_CHARACTERS = ('0'..'9').to_a + ('a'..'f').to_a
class UDID
  LENGTH = 40
  def self.generate
    LENGTH.times.map { ::HEX_CHARACTERS.sample }.join
  end
end

class TitleGenerator
  LEVELS      = ['Assistant', 'Assistant to the', 'Chief', 'Grand Master', 'Junior', 'Lead', 'Overseer of', 'Primary', 'Secondary', 'Senior', 'Tertiary']
  DEPARTMENTS = ['Accounting', 'Accounts Payable', 'Accounts Receivable', 'Business Development', 'Customer Service', 'Devops', 'Developer Relations', 'Duck', 'Engineering', 'Financial', 'Fraud Prevention', 'Human Resources', 'IT', 'Inside Sales', 'Janitorial', 'Marketing', 'Office', 'Outside Sales', 'Payops', 'Product', 'Public Relations', 'Regional', 'Zombie Apocalypse']
  DUTIES      = ['Analyst', 'Architect', 'Coordinator', 'Czar', 'Deck Swab', 'Developer', 'Engineer', 'Gangster', 'Inspector', 'Manager', 'Ninja', 'Pirate', 'Rogue', 'Scallywag', 'Specialist', 'Warrior', 'Wizard']
  SALT        = 692
  def self.title_for(name)
    require 'digest/sha1'
    i = (Digest::SHA1.hexdigest(name.to_s).to_i(16) + SALT)
    "#{level(i)} #{department(i)} #{duty(i)}"
  end

  def self.level(i);      LEVELS.     mod(i); end
  def self.department(i); DEPARTMENTS.mod(i); end
  def self.duty(i);       DUTIES.     mod(i); end
end

COUNTRIES = Earth::Country::ALL

FactoryGirl.define do
  sequence(:callback_url)     { |n| "http://callbackurl.com/#{n}"}
  sequence(:conversion_rate)  { |n| n }
  sequence(:country)          { |n| COUNTRIES.mod(n) }
  sequence(:email)            { |n| "user#{n}@email.com" }
  sequence(:guid)             { |n| "#{UUIDTools::UUID.random_create}" }
  sequence(:integer)          { |n| n }
  sequence(:name)             { |n| "Name #{n}" }
  sequence(:partner_name)     { |n| "Partner #{n}"}
  sequence(:title)            { |n| TitleGenerator.title_for(n.to_s) }
  sequence(:udid)             { |n| UDID.generate }
  sequence(:url)              { |n| "http://example.com/#{n}" }
  sequence(:advertising_id)   { |n| "#{UUIDTools::UUID.random_create}".downcase.gsub(/-/, '') }
end
