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

  scope :to_payout, select("#{Reseller.quoted_table_name}.*, sum(pending_earnings) AS pending_earnings, sum(next_payout_amount) AS next_payout_amount").
    where("#{Partner.quoted_table_name}.pending_earnings != ?", 0).
    joins(:partners).order("#{Reseller.quoted_table_name}.name ASC").group("#{Partner.quoted_table_name}.reseller_id")
  scope :payout_info_changed, lambda { |start_date, end_date|
    joins(:partners => :payout_info).where("#{PayoutInfo.quoted_table_name}.updated_at >= ? and #{PayoutInfo.quoted_table_name}.updated_at < ? ", start_date, end_date)
  }

  # These attributes are from the .to_payout scope and need to be read as floats, not strings.
  %w(pending_earnings next_payout_amount).each do |field|
    define_method field do
      (read_attribute(field) || 0).to_f
    end
  end

  def leftover_payout_amount
    pending_earnings - next_payout_amount
  end

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
