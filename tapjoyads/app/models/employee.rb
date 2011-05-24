class Employee < ActiveRecord::Base
  validates_presence_of :first_name, :last_name, :title, :email
  validates_uniqueness_of :email
  validates_format_of :photo_content_type,
                      :with => /^image/,
                      :if => Proc.new { |emp| !emp.photo_content_type.nil? },
                      :message => "--- you can only upload pictures"
  
  named_scope :active_only, :conditions => 'active = true', :order => 'last_name, first_name'
  
  def full_name
    first_name + " " + last_name + ", " + title
  end
  
  def photo_file_name
    first_name + "_" + last_name
  end
  
  def uploaded_photo=(picture_field)
    self.photo_content_type = picture_field.content_type.chomp
    self.photo = picture_field.read
  end
  
  def delete_photo
    if self.photo != nil
      self.photo = nil
    end
  end
end
