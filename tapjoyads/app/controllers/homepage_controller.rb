class HomepageController < WebsiteController
  layout 'homepage'
  protect_from_forgery :except => [:contact]

  def start
    if permitted_to?(:index, :statz)
      redirect_to statz_index_path
    elsif permitted_to?(:index, :apps)
      redirect_to apps_path
    elsif current_partner.nil?
      render :action => 'index'
    end
  end

  def contact
    if (params[:info])
      TapjoyMailer.deliver_contact_us(params[:info])
      redirect_to :action => 'contact-thanks'
    end
  end

  def privacy
    render :layout => false
  end

  def press_entry
    sanitized_id = params[:id].split('-').first
    render "homepage/press/#{sanitized_id}", :layout => 'press'
  end

  def press
    @press_list = [
      [
        "2.9.2011",
        "Tapjoy Launches Pay-Per-Action&trade; Distribution Model for Android, iOS Applications; Analytics Partnership with Apsalar",
        "/press/201102090-tapjoy-launches-pay-per-action-analytics-partnership-with-apsalar",
      ],
      [
        "1.6.2011",
        "Tapjoy Closes $21 Million Funding to Accelerate Growth as the Clear Leader in Monetization and Distribution for Application Developers",
        "/press/tapjoy-closes-21-million-funding.html",
      ],
      [
        "11.9.2010",
        "Tapjoy acquires AppStrip for Cross-App Promotion",
        "http://blog.tapjoy.com/2010/11/09/offerpal-acquires-appstrip/",
      ],
      [
        "10.6.2010",
        "Offerpal Media Changes Name to Tapjoy, Inc.",
        "/press/offerpal-media-changes-name.html",
      ],
      [
        "9.3.2010",
        "Offerpal Media Names Mihir Shah CEO; George Garrick Executive Chairman",
        "/press/chief-executive-officer.html",
      ],
      [
        "7.20.2010",
        "Offerpal Media Launches New Cross-Platform User Acquisition and Re-engagement Channel for Social Game Developers",
        "/press/cross-platform-user-acquisition.html",
      ],
      [
        "7.7.2010",
        "Offerpal Media to Deliver Monetization Services for Social Game Developers on the Yahoo! Application Platform",
        "/press/monetization-for-yahoo-platform.html",
      ],
      [
        "6.17.2010",
        "Offerpal Media Helps Game Developers Triple Offer-Based Revenue With In-Game Promotional Campaigns ",
        "/press/in-game-promotional-campains.html",
      ],
      [
        "6.10.2010",
        "GameDuell, Snail Games USA, OMGPOP and The9 Choose Offerpal Media for Virtual Currency Monetization",
        "/press/leading-mmos-sites-integrate-offerpal.html",
      ],
      [
        "5.27.2010",
        "GamePoints.com Tops Half a Million Users in First Month",
        "/press/gamepoints-tops-half-million.html",
      ],
      [
        "5.4.2010",
        "Offerpal Media Launches GamePoints.com for Consumers to Earn Gaming Currency",
        "/press/launch-gamepoints.html",
      ],
      [
        "4.20.2010",
        "Offerpal Media Launches Display Ad Network for Social Media ",
        "/press/adnetwork_sm.html",
      ],
      [
        "4.8.2010",
        "Offerpal Media Rolls Out New Direct Payment Options Worldwide, Hires Industry Veteran Alex Brutin",
        "/press/alex-brutin.html",
      ],
      [
        "3.23.2010",
        "Offerpal Media Acquires Leading Mobile Monetization Provider Tapjoy ",
        "/press/offerpal-tapjoy.html",
      ],
      [
        "3.23.2010",
        "Offerpal Media Publishes New Policies for Mobile Advertising Offers ",
        "/press/mobile-advertising-offers.html",
      ],
      [
        "3.10.2010",
        "More than Half of Social Gamers Willing to Complete a Marketing Action to Earn Virtual Currency, According to Study for Offerpal Media by comScore",
        "/press/social-gamers.html",
      ],
      [
        "2.18.2010",
        "Offerpal Hosts Forum on the Future of Social and Mobile Gaming at GDC 2010",
        "/press/gdc-2010.html",
      ],
      [
        "2.9.2010",
        "Offerpal Media Leverages Amazon Mechanical Turk to Launch Offerpal Tasks",
        "/press/offerpal_tasks.html",
      ],
      [
        "12.22.2009",
        "Offerpal Media Powers Virtual Currency Monetization for MMA Pro Fighter ",
        "/press/mma_profighter.html",
      ],
      [
        "12.15.2009",
        "Offerpal Media Names Mihir Shah as Chief Revenue Officer",
        "/press/chief_revenue_officer.html",
      ],
      [
        "12.1.2009",
        "Offerpal Media Launches New Rewards Program for Gamers to Earn Virtual Currency by Shopping Online",
        "/press/offerpal_new_shopping.html",
      ],
      [
        "11.19.2009",
        "Offerpal Media Publishes Advertising Policies for Virtual Currency Offers, Develops Tools and Processes to Ensure Compliance",
        "/press/offerpal_publish_advertising.html",
      ],
      [
        "11.4.2009",
        "Offerpal Media Names George Garrick CEO",
        "/press/george-garrick.html",
      ],
      [
        "10.29.2009",
        "Offerpal Media Marks Two-Year Anniversary with 160 Million Users and 730 Billion Virtual Points Issued",
        "/press/two-year-anniversary.html",
      ],
      [
        "9.30.2009",
        "Offerpal Media Introduces Offerpal SURVEYS, Enabling Game Developers to Monetize Through Online Survey Offers",
        "/press/offerpal_surveys.html",
      ],
      [
        "9.22.2009",
        "Offerpal Media Powers Virtual  Currency Monetization for Mindspark&rsquo;s Zwinky &reg; and IWON &reg; Properties",
        "/press/power_vcurrency.html",
      ],
      [
        "9.16.2009",
        "Offerpal Media Launches Multivariate Testing Platform for Online Game Developers",
        "/press/multivariate-testing.html",
      ],
      [
        "7.22.2009",
        "Offerpal Media Surpasses 100 Million User Accounts",
        "/press/offerpal-million.html",
      ],
      [
        "7.16.2009",
        "Offerpal Media Launches OfferpalSECURE to Fight Virtual Currency Fraud",
        "/press/offerpal-secure.html",
      ],
      [
        "6.25.2009",
        "Offerpal Media Partners with Tapjoy to Drive New Revenue Streams for iPhone Application Developers",
        "/press/tapjoy-partners.html",
      ],
      [
        "6.18.2009",
        "Offerpal Media Launches the First Customizable Virtual Currency Analytics Package for Social Applications and Destination Sites",
        "/press/virtual-currency.html",
      ],
    ]
    @news_list = [
      [
        "1.6.2011",
        "SocialTimes",
        "TapJoy Taps $21M In Funding",
        "http://www.socialtimes.com/2011/01/tapjoy-taps-21m-in-funding/",
      ],
      [
        "11.10.2010",
        "Gamasutra",
        "Tapjoy Buys AppStrip for Social Game Cross-Promotion",
        "http://www.gamasutra.com/view/news/31468/Tapjoy_Buys_AppStrip_For_Social_Game_CrossPromotion.php",
      ],
      [
        "7.20.2010",
        "TechCrunch",
        "Offerpal Moves On, Gives Game Developers New Ways To Distribute Notifications",
        "http://techcrunch.com/2010/07/20/offerpal-socialkast/",
      ],
      [
        "7.20.2010",
        "VentureBeat",
        "Offerpal launches SocialKast to recruit social game fans on any site",
        "http://games.venturebeat.com/2010/07/20/offerpal/",
      ],
      [
        "7.20.2010",
        "Inside Social Games",
        "Offerpal Launches SocialKast to Help Games Migrate Off Facebook",
        "http://www.insidesocialgames.com/2010/07/20/socialkast-offerpal-games-migrate-off-facebook/",
      ],
      [
        "7.20.2010",
        "Virtual Goods News",
        "Offerpal Launches SocialKast To Support Viral Game Spread",
        "http://www.virtualgoodsnews.com/2010/07/offerpal-launches-socialkast-to-support-viral-game-spread.html",
      ],
      [
        "7.7.2010",
        "VentureBeat",
        "Offerpal to help Yahoo&apos;s developers make money on apps",
        "http://games.venturebeat.com/2010/07/07/offerpal-to-help-yahoos-developers-to-monetize-their-applications/",
      ],
      [
        "7.7.2010",
        "Inside Social Games",
        "Offerpal Wants to Monetize Social Games on Yahoo&apos;s Developer Platform",
        "http://www.insidesocialgames.com/2010/07/07/offerpal-wants-to-monetize-social-games-on-yahoos-developer-platform/",
      ],
      [
        "7.6.2010",
        "Gamezebo",
        "Yahoo! about to announce games deal with Offerpal to compete against Facebook",
        "http://www.gamezebo.com/news/2010/07/06/yahoo-about-announce-games-deal-offerpal-compete-against-facebook",
      ],
      [
        "6.18.2010",
        "Games.com",
        "Offerpal: In-game offers triples advertising revenue",
        "http://blog.games.com/2010/06/18/offerpal-in-game-offers-triples-advertising-revenue/",
      ],
      [
        "6.17.2010",
        "SocialTimes",
        "Offerpal's In-Game Promotions Increase Developers Offer Revenue By 3X",
        "http://www.socialtimes.com/2010/06/offerpals-in-game-promotions-help-developers-triple-offer-related-revenue/",
      ],
      [
        "6.17.2010",
        "Virtual Goods News",
        "Offerpal: In-Game Promotions Triple Offer Revenue",
        "http://www.virtualgoodsnews.com/2010/06/offerpal-ingame-promotions-triple-offer-revenue.html",
      ],
      [
        "5.28.2010",
        "VentureBeat",
        "Offerpal's GamePoints virtual currency draws half a million users in three weeks",
        "http://social.venturebeat.com/2010/05/28/offerpals-gamepoints-virtual-currency-draws-half-a-million-users-in-three-weeks/",
      ],
      [
        "5.28.2010",
        "SocialTimes",
        "Offerpal's GamePoints.com Service Engages Over 500,000 Users In First Month",
        "http://www.socialtimes.com/2010/05/offerpals-gamepoints-com-service-engages-over-500000-users-in-first-month/",
      ],
      [
        "5.27.2010",
        "Virtual Goods News",
        "Over 500K Users For Offerpal's GamePoints.com",
        "http://www.virtualgoodsnews.com/2010/05/over-500k-users-for-offerpals-gamepointscom-.html",
      ],
      [
        "5.4.2010",
        "Fast Company",
        "Offerpal Joins the Virtual Currency Game, Battling The Big One: Facebook",
        "http://www.fastcompany.com/1637259/virtual-currency-offerpal-facebook-credits-virtual-money-exchange-gamepoints",
      ],
      [
        "5.4.2010",
        "Inside Social Games",
        "Offerpal Launches Its Own Virtual Goods Currency",
        "http://www.insidesocialgames.com/2010/05/04/embargo/",
      ],
      [
        "5.4.2010",
        "Fast Company",
        "Offerpal Media launches a virtual money war with Facebook",
        "http://games.venturebeat.com/2010/05/04/offerpal-media-launches-a-virtual-money-war-with-facebook/",
      ],
      [
        "5.4.2010",
        "Virtual Goods News",
        "Offerpal Launches Virtual Currency Portal",
        "http://www.virtualgoodsnews.com/2010/05/offerpal-launches-virtual-currency-portal.html",
      ],
      [
        "4.20.2010",
        "VentureBeat",
        "Offerpal becomes one-stop shop for ads and offers",
        "http://games.venturebeat.com/2010/04/20/offerpal-becomes-one-stop-shop-for-ads-and-offers",
      ],
      [
        "4.20.2010",
        "MediaBistro",
        "Offerpal Adds Display Network",
        "http://www.mediapost.com/publications/?fa=Articles.showArticle&art_aid=126558",
      ],
      [
        "4.20.2010",
        "Virtual Goods News",
        "Offerpal Launches Display Ad Network",
        "http://www.virtualgoodsnews.com/2010/04/offerpal-launches-display-ad-network.html",
      ],
      [
        "4.20.2010",
        "Social Times",
        "Offerpal Media Adds Display Ad Network To Their Social Media Offerings",
        "http://www.socialtimes.com/2010/04/offerpal-media-adds-display-ad-network-to-their-social-media-offerings/?utm_source=feedburner&utm_medium=twitter&utm_campaign=Feed%3A+socialtimes+%28SocialTimes.com%29",
      ],
      [
        "3.22.2010",
        "TechCrunch",
        "Offerpal Media Acquires Tapjoy, Gains Beachhead For Mobile App Monetization",
        "http://techcrunch.com/2010/03/22/offerpal-media-acquires-tapjoy-gains-beachhead-for-mobile-app-monetization",
      ],
      [
        "3.23.2010",
        "Inside Social Games",
        "Offerpal Moves Further Into Mobile Social Monetization with Tapjoy Purchase, Publishes Mobile Ad Policy",
        "http://www.insidesocialgames.com/2010/03/23/offerpal-moves-further-into-mobile-social-monetization-with-tapjoy-purchase-publishes-mobile-ad-policy",
      ],
      [
        "3.23.2010",
        "Silicon Valley Business Journal",
        "Offerpal Media acquires Tapjoy",
        "http://www.bizjournals.com/sanjose/stories/2010/03/22/daily27.html",
      ],
      [
        "3.23.2010",
        "Gamasutra",
        "Offerpal Acquires Tapjoy For Mobile App Monetization",
        "http://www.gamasutra.com/view/news/27790/Offerpal_Acquires_Tapjoy_For_Mobile_App_Monetization.html",
      ],
      [
        "3.23.2010",
        "MediaPost",
        "iPhone Lays Ground for iPad as Game Player",
        "http://www.mediapost.com/publications/?fa=Articles.showArticle&art_aid=124829",
      ],
      [
        "3.23.2010",
        "PocketGamer",
        "It's monetisation consolidation as Offerpal Media picks up Tapjoy",
        "http://www.pocketgamer.biz/r/PG.Biz/TapJoy+SDK/news.asp?c=19323",
      ],
      [
        "2.9.2010",
        "Inside Social Games",
        "Offerpal Uses Amazon's Mechanical Turk to Provide Online Work for Earning Virtual Currency",
        "http://www.insidesocialgames.com/2010/02/09/offerpal-uses-amazons-mechanical-turk-to-provide-online-work-for-earning-virtual-currency",
      ],
    ]
  end
end
