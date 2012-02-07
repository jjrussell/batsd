module PressHelper
  def press_contact(person)
    if person == :tapjoy
      press_contact({ :name => 'Shannon Jessup', :company => 'Tapjoy', :phone => '(415) 766-6956', :email => 'shannon.jessup@tapjoy.com' })
    elsif person == :media
      press_contact({ :name => 'Stephanie Holbrook', :company => 'Tapjoy, Inc.', :phone => '(415) 766-6996', :email => 'stephanie@tapjoy.com' })
    else
      "<p class='contact'>#{person[:name]}<br/>#{person[:company]}<br/>#{person[:phone]}<br/>#{mail_to(person[:email])}<br/></p>"
    end
  end
end
