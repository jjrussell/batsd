class Transfer < ActiveRecord::BaseWithoutTable

  column :amount, :integer
  column :internal_notes, :string

  validates_presence_of :amount
  validates_presence_of :internal_notes
  validates_numericality_of :amount, :only_integer => true

end
