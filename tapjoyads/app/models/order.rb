class Order < ActiveRecord::Base
  include UuidPrimaryKey

  STATUS_CODES = {
    0 => 'Failed Invoice',
    1 => 'Normal',
  }

  PAYMENT_METHODS = {
    0 => 'Website',
    1 => 'Invoice',
    2 => 'Bonus',
    3 => 'Transfer',
  }

  belongs_to :partner
  
  validates_presence_of :partner
  validates_presence_of :billing_email, :on => :create, :if => :billable?, :message => "Partner needs a billing email for invoicing"
  validates_inclusion_of :status, :in => STATUS_CODES.keys
  validates_inclusion_of :payment_method, :in => PAYMENT_METHODS.keys
  validates_uniqueness_of :invoice_id, :allow_nil => true
  validates_numericality_of :amount, :only_integer => true, :allow_nil => false
  
  after_create :update_balance, :create_spend_discount

  delegate :billing_email, :freshbooks_client_id, :to => :partner

  named_scope :not_invoiced, :conditions => 'status = 0'
  named_scope :created_since, lambda { |date| { :conditions => [ "created_at > ?", date ] } }
  named_scope :created_between, lambda { |start_time, end_time| { :conditions => [ "created_at >= ? AND created_at < ?", start_time, end_time ] } }
  named_scope :for_discount, lambda { created_since(3.months.ago.to_date).scoped(:order => 'created_at DESC').scope(:find) }
  
  def <=> other
    created_at <=> other.created_at
  end
  
  def status_string
    STATUS_CODES[status]
  end

  def payment_method_string
    PAYMENT_METHODS[payment_method]
  end

  def is_order?;    payment_method==0;  end
  def is_invoiced?; payment_method==1;  end
  def is_bonus?;    payment_method==2;  end
  def is_transfer?; payment_method==3;  end

  def create_freshbooks_invoice!
    return if invoice_id

    unless freshbooks_client_id
      partner.freshbooks_client_id = FreshBooks.get_client_id(billing_email)
      partner.save! if freshbooks_client_id
    end

    if freshbooks_client_id
      self.invoice_id = FreshBooks.create_invoice(invoice_details)
      self.status = 1
    else
      self.status = 0
    end
    self.save!
  end

  def failed_invoice?
    status == 0
  end

  def billable?
    payment_method_string == 'Invoice'
  end

private

  def invoice_details
    {
      :invoice => {
        :client_id => freshbooks_client_id,
        :invoice_id => invoice_id,
        :notes => note_to_client,
        :lines => [
          {
            :name => 'TapjoyAdsCredit',
            :description => description,
            :unit_cost => 1,
            :quantity => amount / 100.0,
            :type => 'Item',
          },
        ],
      }
    }
  end

  def update_balance
    return true if amount == 0
    Partner.connection.execute("UPDATE partners SET balance = (balance + #{amount}) WHERE id = '#{partner_id}'")
  end
  
  def create_spend_discount
    sum = 0
    partner.orders.for_discount.each do |order|
      sum += order.amount
      if sum >= 15000000
        OfferDiscount.create!(:partner => partner, :source => 'Spend', :amount => 15, :expires_on => order.created_at + 3.months)
        break
      end
    end
  end
  
end
