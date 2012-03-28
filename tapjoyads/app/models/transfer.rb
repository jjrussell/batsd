class Transfer
  include ActiveModel::Validations

  attr_accessor :amount, :internal_notes

  validates_presence_of :amount
  validates_presence_of :internal_notes
  validates_numericality_of :amount, :only_integer => true

end
