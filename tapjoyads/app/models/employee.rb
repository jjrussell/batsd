class Employee < ActiveRecord::Base
  validates_presence_of :first_name, :last_name, :title, :email
#  validates_format_of :content_type,
#                      :with => /^image/,
#                      :message => "--- you can onlly upload pictures"
  
  named_scope :active_only, :conditions => 'active = true', :order => 'last_name, first_name'
  
  def full_name
    first_name + " " + last_name + ", " + title
  end
  
  def uploaded_photo=(picture_field)
#    self.name = base_part_of(picture_field.original_filename)
#    content_type = picture_field.content_type.chomp
    self.photo = picture_field.read
  end
  
  def base_part_of(file_name)
    File.basename(file_name).gsub(/[^\w._-]/, '')
  end
  
end
