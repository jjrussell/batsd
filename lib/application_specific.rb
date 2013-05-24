module ApplicationSpecific

  def self.included(model)
    model.class_eval do
      default_scope { where(:application => ApplicationSpecific.app_name) }
      after_initialize :set_application
    end
  end

  protected

  def set_application
    self.application = ApplicationSpecific.app_name
  end

  def self.app_name
    Rails.application.class.to_s.split('::').first.downcase
  end
end
