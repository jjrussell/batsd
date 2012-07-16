class OneOffs
  def self.reset_uses_non_html_field
    App.update_all(:uses_non_html_responses => false)
  end
end
