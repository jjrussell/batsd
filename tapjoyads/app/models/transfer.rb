class Transfer
  include ActiveModel::Validations

  validates_presence_of :amount
  validates_presence_of :internal_notes
  validates_numericality_of :amount, :only_integer => true

  def initialize(attributes = {})
    @attributes = attributes
  end
 
  def read_attribute_for_validation(key)
    @attributes[key]
  end

  def method_missing(attr)
    attr = @attributes[attr]
    if attr
      return attr
    else
      super
    end
  end

end
