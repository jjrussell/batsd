# == Schema Information
#
# Table name: resellers
#
#  id                 :string(36)      not null, primary key
#  name               :string(255)
#  reseller_rev_share :decimal(8, 6)   not null
#  rev_share          :decimal(8, 6)   not null
#  created_at         :datetime
#  updated_at         :datetime
#

class Reseller < ActiveRecord::Base
  include UuidPrimaryKey

  has_many :users, :dependent => :nullify
  has_many :partners, :dependent => :nullify
  has_many :currencies, :dependent => :nullify
  has_many :offers, :dependent => :nullify

  after_save :update_partners_and_currencies

  validates_presence_of :name
  validates_numericality_of :rev_share, :reseller_rev_share, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 1

  def update_partners_and_currencies
    if rev_share_changed?
      partners.each do |p|
        p.update_attribute :rev_share, rev_share
      end
    end
    if reseller_rev_share_changed?
      currencies.each do |c|
        c.calculate_spend_shares
        c.save!
      end
    end
  end
end
