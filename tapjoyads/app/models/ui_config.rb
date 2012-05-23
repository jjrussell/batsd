class UiConfig

  def self.is_fb_signup_hidden
    Mc.get('tjm.ui.hide_fb_signup')
  end

  def self.hide_fb_signup
    Mc.put('tjm.ui.hide_fb_signup', true)
  end

  def self.show_fb_signup
    Mc.delete('tjm.ui.hide_fb_signup')
  end

end
