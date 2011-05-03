module PressHelper
  def press_contact(person)
    if person == :tapjoy
      press_contact({ :name => 'Shannon Jessup', :company => 'Tapjoy', :phone => '(805) 698-3851', :email => 'shannon.jessup@tapjoy.com' })
    elsif person == :media
      press_contact({ :name => 'Matt McAllister', :company => 'Fluid Communications Group', :phone => '(510) 229-9707', :email => 'matt.mcallister@tapjoy.com' })
    else
      "<p class='contact'>#{person[:name]}<br/>#{person[:company]}<br/>#{person[:phone]}<br/>#{mail_to(person[:email])}<br/><br/></p>"
    end
  end

  def mail_to(email)
    "<a href='#{email}'>#{email}</a>"
  end

  def link_to_tapjoy
    '<a href="https://www.tapjoy.com/">www.tapjoy.com</a>'
  end

  def link_to_offerpal(text='www.offerpalmedia.com')
    "<a href=\"http://www.offerpalmedia.com\">#{text}</a>"
  end
end
