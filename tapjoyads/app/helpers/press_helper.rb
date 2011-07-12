module PressHelper
  def press_contact(person)
    if person == :tapjoy
      press_contact({ :name => 'Shannon Jessup', :company => 'Tapjoy', :phone => '(415) 766-6956', :email => 'shannon.jessup@tapjoy.com' })
    elsif person == :media
      press_contact({ :name => 'Matt McAllister', :company => 'Fluid PR', :phone => '(510) 229-9707', :email => 'matt@fluidspeak.com' })
    else
      "<p class='contact'>#{person[:name]}<br/>#{person[:company]}<br/>#{person[:phone]}<br/>#{mail_to(person[:email])}<br/></p>"
    end
  end
end
