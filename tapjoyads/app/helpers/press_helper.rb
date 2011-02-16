module PressHelper
  def press_contact(person)
    if person == :tapjoy
      press_contact({ :name => 'Shannon Jessup', :company => 'Tapjoy', :phone => '(805) 698-3851', :email => 'shannon.jessup@tapjoy.com' })
    elsif person == :media
      press_contact({ :name => 'Matt McAllister', :company => 'Fluid Communications Group', :phone => '(510) 229-9707', :email => 'matt.mcallister@tapjoy.com' })
    else
      concat(person[:name])
      concat("<br/>")
      concat(person[:company])
      concat("<br/>")
      concat(person[:phone])
      concat("<br/>")
      concat(mail_to(person[:email]))
      concat("<br/>")
      concat("<br/>")
    end
  end

  def link_to_tapjoy(text='www.tapjoy.com')
    link_to(text, root_path)
  end

  def link_to_offerpal(text='www.offerpalmedia.com')
    link_to(text, 'http://www.offerpalmedia.com')
  end

  def press_date(location="San Francisco, CA")
    date_string = "#{params[:id][0..3]}-#{params[:id][4..5]}-#{params[:id][6..7]}"
    date = Date.parse(date_string).strftime("%B %-1d, %Y")
    location = "Fremont, CA" if location == :fremont
    concat("<strong>#{location} &ndash; #{date}</strong> &ndash; ")
  end

  def about_blurb(company=:tapjoy)
    if company == :offerpal
      concat("<h2>About Offerpal Media</h2>")
      concat("Offerpal Media is the first \"Managed Offer Platform\" for social applications, online communities and <nobr>e-commerce</nobr> sites. The company's turnkey platform allows developers of social applications on networks such as Facebook, MySpace, Bebo, hi5 and others to monetize their traffic through uniquely engineered offers. Meanwhile, advertisers can tap into Offerpal Media's expansive network to reach more than 50 million highly engaged and targeted consumers on social networks. The platform also helps online merchants generate incremental revenue by using ad offers as an alternate payment method. Based in Fremont, CA, and backed by top-tier venture capital firms, Offerpal Media features an experienced management team with deep roots in online advertising, personalization, and optimization technologies. For more information, visit #{link_to_offerpal}.")
    else
      concat("<h2>About Tapjoy, Inc.</h2>")
      concat("Tapjoy is the leader in monetization, distribution and publishing services for social games, mobile applications, virtual worlds, MMOs and other social publishers. The company's turnkey alternative payment platform enables developers to significantly increase their monetization rates when selling virtual goods or premium digital assets, while its cross-platform distribution services provide massive reach and cost-effective user acquisition on the leading social, mobile and gaming platforms. The company is headquartered in San Francisco, California. Investors include Rho Ventures, Interwest Capital, North Bridge Venture Partners, and D. E. Shaw Ventures. For more information, visit #{link_to_tapjoy}.")
    end
    concat("<br/><br/>")
  end
end
