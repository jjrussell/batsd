class Transfer < ActiveRecord::BaseWithoutTable

  column :amount, :integer
  column :internal_notes, :string
  column :transfer_type, :integer

  validates_presence_of :amount
  validates_presence_of :internal_notes
  validates_presence_of :transfer_type
  validates_numericality_of :amount, :only_integer => true
  validates_numericality_of :transfer_type, :only_integer => true

end
