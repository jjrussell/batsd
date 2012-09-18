class IdListValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if record.respond_to?(:changes) && record.changes[attribute].nil?
    if value.nil?
      record.errors.add(attribute, 'nil') unless options[:allow_nil]
    elsif value.blank?
      record.errors.add(attribute, 'blank') unless options[:allow_blank]
    else
      type = options[:of]
      sep = options[:separator] || ';'
      value.split(sep).each do |id|
        unless type.find_by_id(id)
          record.errors.add(attribute, options[:message] || "contains an invalid ID value #{id}")
        end
      end
    end
  end
end
