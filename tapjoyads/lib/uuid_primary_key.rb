# Include this module in any model that has a UUID for its primary key.

module UuidPrimaryKey

  # validate that the 'id' field is present and unique
  def self.included(model)
    model.class_eval do
      validates_presence_of :id
      validates_uniqueness_of :id
    end
  end

  # ensures that each new record has a UUID assigned to the 'id' field.
  def before_validation_on_create
    self.id = UUIDTools::UUID.random_create.to_s if id.blank?
  end

end
