class Transfer
  include ActiveModel::Validations

  ATTRIBUTES = %w(amount internal_notes)

  validates_presence_of :amount
  validates_presence_of :internal_notes
  validates_numericality_of :amount, :only_integer => true

  def initialize(attributes = {})
    @attributes = attributes
  end

  def read_attribute_for_validation(key)
    @attributes[key]
  end

  ATTRIBUTES.each do |attr|
    define_method(attr) { @attributes[attr] }
  end

  def to_key
    nil
  end
end
