# Include this module in any model that has a UUID for its primary key.

module UuidPrimaryKey

  # validate that the 'id' field is present and unique
  def self.included(model)
    model.class_eval do
      validates_presence_of :id
      validates_uniqueness_of :id

      before_validation_on_create :set_primary_key
    end
  end

private

  # ensures that each new record has a UUID assigned to the 'id' field.
  def set_primary_key
    self.id = UUIDTools::UUID.random_create.to_s unless id =~ /^[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12}$/
    true
  end

end
