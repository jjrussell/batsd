class CreatePressAndNews < ActiveRecord::Migration
  def self.up
    create_table :press_releases do |t|
      t.timestamp   :published_at,    :nil => false
      t.text        :link_text,       :nil => false
      t.text        :link_href,       :nil => false
      # internal only
      t.string      :link_id
      t.text        :content_title
      t.text        :content_subtitle
      t.text        :content_body
      t.text        :content_about
      t.text        :content_contact

      t.timestamps
    end

    create_table :news_coverages do |t|
      t.timestamp   :published_at,  :nil => false
      t.string      :link_source,   :nil => false
      t.text        :link_text,     :nil => false
      t.text        :link_href,     :nil => false

      t.timestamps
    end

    add_index :press_releases, :published_at
    add_index :news_coverages, :published_at
    press_haml = PressHaml.new
    press_releases.each do |press|
      press_release = {
        :published_at => Date.strptime(press[0], '%m.%d.%Y'),
        :link_text    => press[1]
      }

      press_release[:link_href] = press[2]
      unless press[2] =~ /^http/
        press_release[:link_href] = press[2].split('/').last
        press_release[:link_id] = press_release[:link_href].split('-', 2)[0]
        file_path = RAILS_ROOT + "/app/views/homepage/press/#{press_release[:link_id]}.html.haml"
        File.open(file_path) do |file|
          title = file.readline
          subtitle = file.readline
          unless title.blank?
            press_release[:content_title] = title.split('"', 2).last.reverse.split('"', 2).last.reverse
          end
          unless subtitle.blank?
            press_release[:content_subtitle] = subtitle.split('"', 2).last.reverse.split('"', 2).last.reverse
          end

          body = file.read.
                  gsub('- press_date(:fremont)', '- press_date("Fremont, CA")').
                  gsub('- press_date', '\- press_date').
                  gsub(/%h2 Tapjoy.*$/, '').
                  gsub(/%h2 Company.*$/, '').
                  gsub(/%h2 Media.*$/, '').
                  gsub(/%h2 CONTACT.*$/, '').
                  gsub(/%h2 Contact.*$/, '').
                  gsub(/- about_blurb.*$/, '')

          contacts = body.match(/%h2 [^\n]* Contact:\n= *press_contact[^\n]*\n/).to_a
          press_release[:content_contact] = Haml::Engine.new(contacts.join("\n")).render(press_haml) unless contacts.blank?
          body.gsub!(/%h2 [^\n]* Contact:\n= *press_contact[^\n]*\n/, "")

          press_release[:content_body] = Haml::Engine.new(body).render(press_haml)
        end
      end

      PressRelease.create(press_release)
    end

    news_coverages.each do |news|
      NewsCoverage.create({
        :published_at => Date.strptime(news[0], '%m.%d.%Y'),
        :link_source  => news[1],
        :link_text    => news[2],
        :link_href    => news[3]
      })
    end
  end

  def self.down
    drop_table :press_releases
    drop_table :news_coverages
  end

  def self.press_releases
    [
      [ "3.23.2011", "Tapjoy Fuels Self-Publishing for Mobile and Social Application Developers", "/press/201103230-tapjoy-fuels-self-publishing-for-developers", ],
      [ "3.3.2011", "Tapjoy Helps Fuel the Growth of Glu's Gun Bros App on Mobile Platforms", "/press/201103030-tapjoy-helps-fuel-growth-of-glus-gun-bros", ],
      [ "2.9.2011", "Tapjoy Launches Pay-Per-Action&trade; Distribution Model for Android, iOS Applications; Analytics Partnership with Apsalar", "/press/201102090-tapjoy-launches-pay-per-action-analytics-partnership-with-apsalar", ],
      [ "1.6.2011", "Tapjoy Closes $21 Million Funding to Accelerate Growth as the Clear Leader in Monetization and Distribution for Application Developers", "/press/201101060-tapjoy-closes-21-million-funding", ],
      [ "11.9.2010", "Tapjoy acquires AppStrip for Cross-App Promotion", "http://blog.tapjoy.com/2010/11/09/offerpal-acquires-appstrip/", ],
      [ "10.6.2010", "Offerpal Media Changes Name to Tapjoy, Inc.", "/press/201010060-offerpal-media-changes-name-to-tapjoy", ],
      [ "9.3.2010", "Offerpal Media Names Mihir Shah CEO; George Garrick Executive Chairman", "/press/201009030-offerpal-media-names-mihir-shah-ceo", ],
      [ "7.20.2010", "Offerpal Media Launches New Cross-Platform User Acquisition and Re-engagement Channel for Social Game Developers", "/press/201007200-cross-platform-user-acquisition-channel", ],
      [ "7.7.2010", "Offerpal Media to Deliver Monetization Services for Social Game Developers on the Yahoo! Application Platform", "/press/201007070-monetization-for-yahoo-platform", ],
      [ "6.17.2010", "Offerpal Media Helps Game Developers Triple Offer-Based Revenue With In-Game Promotional Campaigns ", "/press/201006170-in-game-promotional-campains", ],
      [ "6.10.2010", "GameDuell, Snail Games USA, OMGPOP and The9 Choose Offerpal Media for Virtual Currency Monetization", "/press/201006100-leading-mmos-sites-integrate-offerpal", ],
      [ "5.27.2010", "GamePoints.com Tops Half a Million Users in First Month", "/press/201005270-gamepoints-tops-half-million", ],
      [ "5.4.2010", "Offerpal Media Launches GamePoints.com for Consumers to Earn Gaming Currency", "/press/201005040-launch-gamepoints", ],
      [ "4.20.2010", "Offerpal Media Launches Display Ad Network for Social Media ", "/press/201004200-adnetwork_sm", ],
      [ "4.8.2010", "Offerpal Media Rolls Out New Direct Payment Options Worldwide, Hires Industry Veteran Alex Brutin", "/press/201004080-alex-brutin", ],
      [ "3.23.2010", "Offerpal Media Acquires Leading Mobile Monetization Provider Tapjoy ", "/press/201003230-offerpal-tapjoy", ],
      [ "3.22.2010", "Offerpal Media Publishes New Policies for Mobile Advertising Offers ", "/press/201003220-mobile-advertising-offers", ],
      [ "3.10.2010", "More than Half of Social Gamers Willing to Complete a Marketing Action to Earn Virtual Currency, According to Study for Offerpal Media by comScore", "/press/201003100-social-gamers", ],
      [ "2.18.2010", "Offerpal Hosts Forum on the Future of Social and Mobile Gaming at GDC 2010", "/press/201002180-gdc-2010", ],
      [ "2.9.2010", "Offerpal Media Leverages Amazon Mechanical Turk to Launch Offerpal Tasks", "/press/201002090-offerpal_tasks", ],
      [ "12.22.2009", "Offerpal Media Powers Virtual Currency Monetization for MMA Pro Fighter ", "/press/200912220-mma_profighter", ],
      [ "12.15.2009", "Offerpal Media Names Mihir Shah as Chief Revenue Officer", "/press/200912150-chief_revenue_officer", ],
      [ "12.1.2009", "Offerpal Media Launches New Rewards Program for Gamers to Earn Virtual Currency by Shopping Online", "/press/200912010-offerpal_new_shopping", ],
      [ "11.19.2009", "Offerpal Media Publishes Advertising Policies for Virtual Currency Offers, Develops Tools and Processes to Ensure Compliance", "/press/200911190-offerpal_publish_advertising", ],
      [ "11.4.2009", "Offerpal Media Names George Garrick CEO", "/press/200911040-george-garrick", ],
      [ "10.29.2009", "Offerpal Media Marks Two-Year Anniversary with 160 Million Users and 730 Billion Virtual Points Issued", "/press/200910290-two-year-anniversary", ],
      [ "9.30.2009", "Offerpal Media Introduces Offerpal SURVEYS, Enabling Game Developers to Monetize Through Online Survey Offers", "/press/200909300-offerpal_surveys", ],
      [ "9.22.2009", "Offerpal Media Powers Virtual  Currency Monetization for Mindspark&rsquo;s Zwinky &reg; and IWON &reg; Properties", "/press/200909220-power_vcurrency", ],
      [ "9.16.2009", "Offerpal Media Launches Multivariate Testing Platform for Online Game Developers", "/press/200909160-multivariate-testing", ],
      [ "7.22.2009", "Offerpal Media Surpasses 100 Million User Accounts", "/press/200907220-offerpal-million", ],
      [ "7.16.2009", "Offerpal Media Launches OfferpalSECURE to Fight Virtual Currency Fraud", "/press/200907160-offerpal-secure", ],
      [ "6.25.2009", "Offerpal Media Partners with Tapjoy to Drive New Revenue Streams for iPhone Application Developers", "/press/200906250-tapjoy-partners", ],
      [ "6.18.2009", "Offerpal Media Launches the First Customizable Virtual Currency Analytics Package for Social Applications and Destination Sites", "/press/200906180-virtual-currency", ],
      [ "6.9.2009", "Offerpal Media Partners with IMVU to Monetize Virtual Currency and Enrich the User Experience", "/press/200906090-imvu-partnership", ],
      [ "4.30.2009", "Jolt Online Gaming Partners with Offerpal Media to Increase User Engagement, Generate New Revenue Stream", "/press/200904300-jolt-online-gaming", ],
      [ "3.30.2009", "Offerpal Media Partners With Outspark", "/press/200903300-partner-outspark", ],
      [ "3.24.2009", "Offerpal Media Appoints Bill Lonergan as Chief Financial Officer", "/press/200903240-chief-financial-officer", ],
      [ "3.19.2009", "Offerpal Media Launches Onboarding Application for Destination Web Publishers", "/press/200903190-web-publishers", ],
      [ "3.11.2009 ", "Offerpal Media Partners with Aeria Games to Monetize Virtual Currency, Increase User Engagement", "/press/200903110-partner-aeria-games", ],
      [ "1.22.2009", "Offerpal Media Named AlwaysOn OnMedia 100 Winner", "/press/200901220-onmedia-winner", ],
      [ "1.14.2009", "Offerpal Media Launches Monetization Platform for iPhone Applications", "/press/200901140-iphone-apps", ],
      [ "12.16.2008", "Offerpal Media Sheds Light on Virtual Gifting, Highlights This Season's Hottest Ways to Spread Holiday Cheer Online", "/press/200812160-virtual_gifting", ],
      [ "11.20.2008", "Offerpal Media Publishes Industry Report on Monetizing Social Traffic through Virtual Currency", "/press/200811200-industry-report", ],
      [ "11.12.2008", "Facebook Developers Garage Hosted by Offerpal Media to Showcase Innovators Behind Social Networking's Hottest Applications", "/press/200811120-facebook-developer-garage-hosted-by-offerpal", ],
      [ "10.27.2008", "Offerpal Media CEO Anu Shukla to Address User Engagement and Monetization at SNAP Summit", "/press/200810270-snap-summit", ],
      [ "9.3.2008", "Offerpal Media Launches Onboarding Application for MySpace Platform", "/press/200809030-myspace-onboard", ],
      [ "8.7.2008", "Offerpal Media's Install Program Helps Social Applications Grow", "http://myofferpal.wordpress.com/2008/08/07/grow-your-app-with-offerpals-install-program/", ],
      [ "7.17.2008", "Offerpal Media Selected as AO Global 250 Winner", "http://myofferpal.wordpress.com/2008/07/17/offerpal-media-selected-as-ao-global-250-winner/", ],
      [ "6.6.2008", "Offerpal Media CEO to speak at Graphing Social Patterns Conference", "http://en.oreilly.com/gspeast2008/public/schedule/detail/3265", ],
    ]
  end

  def self.news_coverages
    [
      [ "2.16.2011", "Gamezebo", "Interview with Shannon Jessup, Tapjoy", "http://www.gamezebo.com/news/2011/02/16/interview-shannon-jessup-tapjoy", ],
      [ "2.10.2011", "ReadWriteWeb", "A New Distribution Model for Apps: Tapjoy's Pay-Per-Action Service  ", "http://www.readwriteweb.com/mobile/2011/02/new-distribution-model-for-apps-tapjoy-pay-per-action-service.php", ],
      [ "2.10.2011", "Inside Social Games", "Tapjoy Launches Pay-Per-Action Mobile Advertising as Installs Get Crowded", "http://www.insidesocialgames.com/2011/02/09/tapjoy-pay-per-action/", ],
      [ "2.10.2011", "Adotas", "Tapjoy Plants Pay-Per-Action Into Mobile Apps", "http://www.adotas.com/2011/02/tapjoy-plants-pay-per-action-into-mobile-apps/", ],
      [ "2.10.2011", "IntoMobile", "Tapjoy launches Pay-Per-Action app distribution service with powerful analytics from Apsalar", "http://www.intomobile.com/2011/02/10/tapjoy-pay-per-action-distribution/", ],
      [ "1.10.2011", "GigaOm", "Alternative Payment Services Ride the Freemium App Boom", "http://gigaom.com/2011/01/10/alternative-payment-services-ride-the-freemium-app-boom/", ],
      [ "1.6.2011", "All Things Digital", "Tapjoy Raises $21 Million to Complete Extreme Makeover", "http://emoney.allthingsd.com/20110106/tapjoy-raises-21-million-to-complete-extreme-makeover/?mod=ATD_skybox", ],
      [ "1.6.2011", "Inside Mobile Apps", "Tapjoy Raises $21 Million to Fuel Growth on Mobile Platforms", "http://www.insidemobileapps.com/2011/01/06/tapjoy-21-million/", ],
      [ "1.6.2011", "SocialTimes", "TapJoy Taps $21M In Funding", "http://www.socialtimes.com/2011/01/tapjoy-taps-21m-in-funding/", ],
      [ "11.10.2010", "Gamasutra", "Tapjoy Buys AppStrip for Social Game Cross-Promotion", "http://www.gamasutra.com/view/news/31468/Tapjoy_Buys_AppStrip_For_Social_Game_CrossPromotion.php", ],
      [ "7.20.2010", "TechCrunch", "Offerpal Moves On, Gives Game Developers New Ways To Distribute Notifications", "http://techcrunch.com/2010/07/20/offerpal-socialkast/", ],
      [ "7.20.2010", "VentureBeat", "Offerpal launches SocialKast to recruit social game fans on any site", "http://games.venturebeat.com/2010/07/20/offerpal/", ],
      [ "7.20.2010", "Inside Social Games", "Offerpal Launches SocialKast to Help Games Migrate Off Facebook", "http://www.insidesocialgames.com/2010/07/20/socialkast-offerpal-games-migrate-off-facebook/", ],
      [ "7.20.2010", "Virtual Goods News", "Offerpal Launches SocialKast To Support Viral Game Spread", "http://www.virtualgoodsnews.com/2010/07/offerpal-launches-socialkast-to-support-viral-game-spread.html", ],
      [ "7.7.2010", "VentureBeat", "Offerpal to help Yahoo&apos;s developers make money on apps", "http://games.venturebeat.com/2010/07/07/offerpal-to-help-yahoos-developers-to-monetize-their-applications/", ],
      [ "7.7.2010", "Inside Social Games", "Offerpal Wants to Monetize Social Games on Yahoo&apos;s Developer Platform", "http://www.insidesocialgames.com/2010/07/07/offerpal-wants-to-monetize-social-games-on-yahoos-developer-platform/", ],
      [ "7.6.2010", "Gamezebo", "Yahoo! about to announce games deal with Offerpal to compete against Facebook", "http://www.gamezebo.com/news/2010/07/06/yahoo-about-announce-games-deal-offerpal-compete-against-facebook", ],
      [ "6.18.2010", "Games.com", "Offerpal: In-game offers triples advertising revenue", "http://blog.games.com/2010/06/18/offerpal-in-game-offers-triples-advertising-revenue/", ],
      [ "6.17.2010", "SocialTimes", "Offerpal's In-Game Promotions Increase Developers Offer Revenue By 3X", "http://www.socialtimes.com/2010/06/offerpals-in-game-promotions-help-developers-triple-offer-related-revenue/", ],
      [ "6.17.2010", "Virtual Goods News", "Offerpal: In-Game Promotions Triple Offer Revenue", "http://www.virtualgoodsnews.com/2010/06/offerpal-ingame-promotions-triple-offer-revenue.html", ],
      [ "5.28.2010", "VentureBeat", "Offerpal's GamePoints virtual currency draws half a million users in three weeks", "http://social.venturebeat.com/2010/05/28/offerpals-gamepoints-virtual-currency-draws-half-a-million-users-in-three-weeks/", ],
      [ "5.28.2010", "SocialTimes", "Offerpal's GamePoints.com Service Engages Over 500,000 Users In First Month", "http://www.socialtimes.com/2010/05/offerpals-gamepoints-com-service-engages-over-500000-users-in-first-month/", ],
      [ "5.27.2010", "Virtual Goods News", "Over 500K Users For Offerpal's GamePoints.com", "http://www.virtualgoodsnews.com/2010/05/over-500k-users-for-offerpals-gamepointscom-.html", ],
      [ "5.4.2010", "Fast Company", "Offerpal Joins the Virtual Currency Game, Battling The Big One: Facebook", "http://www.fastcompany.com/1637259/virtual-currency-offerpal-facebook-credits-virtual-money-exchange-gamepoints", ],
      [ "5.4.2010", "Inside Social Games", "Offerpal Launches Its Own Virtual Goods Currency", "http://www.insidesocialgames.com/2010/05/04/embargo/", ],
      [ "5.4.2010", "Fast Company", "Offerpal Media launches a virtual money war with Facebook", "http://games.venturebeat.com/2010/05/04/offerpal-media-launches-a-virtual-money-war-with-facebook/", ],
      [ "5.4.2010", "Virtual Goods News", "Offerpal Launches Virtual Currency Portal", "http://www.virtualgoodsnews.com/2010/05/offerpal-launches-virtual-currency-portal.html", ],
      [ "4.20.2010", "VentureBeat", "Offerpal becomes one-stop shop for ads and offers", "http://games.venturebeat.com/2010/04/20/offerpal-becomes-one-stop-shop-for-ads-and-offers", ],
      [ "4.20.2010", "MediaBistro", "Offerpal Adds Display Network", "http://www.mediapost.com/publications/?fa=Articles.showArticle&art_aid=126558", ],
      [ "4.20.2010", "Virtual Goods News", "Offerpal Launches Display Ad Network", "http://www.virtualgoodsnews.com/2010/04/offerpal-launches-display-ad-network.html", ],
      [ "4.20.2010", "Social Times", "Offerpal Media Adds Display Ad Network To Their Social Media Offerings", "http://www.socialtimes.com/2010/04/offerpal-media-adds-display-ad-network-to-their-social-media-offerings/?utm_source=feedburner&utm_medium=twitter&utm_campaign=Feed%3A+socialtimes+%28SocialTimes.com%29", ],
      [ "3.22.2010", "TechCrunch", "Offerpal Media Acquires Tapjoy, Gains Beachhead For Mobile App Monetization", "http://techcrunch.com/2010/03/22/offerpal-media-acquires-tapjoy-gains-beachhead-for-mobile-app-monetization", ],
      [ "3.23.2010", "Inside Social Games", "Offerpal Moves Further Into Mobile Social Monetization with Tapjoy Purchase, Publishes Mobile Ad Policy", "http://www.insidesocialgames.com/2010/03/23/offerpal-moves-further-into-mobile-social-monetization-with-tapjoy-purchase-publishes-mobile-ad-policy", ],
      [ "3.23.2010", "Silicon Valley Business Journal", "Offerpal Media acquires Tapjoy", "http://www.bizjournals.com/sanjose/stories/2010/03/22/daily27.html", ],
      [ "3.23.2010", "Gamasutra", "Offerpal Acquires Tapjoy For Mobile App Monetization", "http://www.gamasutra.com/view/news/27790/Offerpal_Acquires_Tapjoy_For_Mobile_App_Monetization.html", ],
      [ "3.23.2010", "MediaPost", "iPhone Lays Ground for iPad as Game Player", "http://www.mediapost.com/publications/?fa=Articles.showArticle&art_aid=124829", ],
      [ "3.23.2010", "PocketGamer", "It's monetisation consolidation as Offerpal Media picks up Tapjoy", "http://www.pocketgamer.biz/r/PG.Biz/TapJoy+SDK/news.asp?c=19323", ],
      [ "2.9.2010", "Inside Social Games", "Offerpal Uses Amazon's Mechanical Turk to Provide Online Work for Earning Virtual Currency", "http://www.insidesocialgames.com/2010/02/09/offerpal-uses-amazons-mechanical-turk-to-provide-online-work-for-earning-virtual-currency", ],
      [ "2.9.2010", "Media Post", "Offerpal Adds New Way To Earn Virtual Currency", "http://www.mediapost.com/publications/?fa=Articles.showArticle&art_aid=122178", ],
      [ "2.9.2010", "AOL Games.com", "Offerpal Tasks offers in-game cash for small jobs", "http://blog.games.com/2010/02/09/offerpal-tasks-offers-in-game-cash-for-small-jobs", ],
      [ "2.9.2010", "VentureBeat", "Offerpal Media lets you pay for games by putting you to work", "http://games.venturebeat.com/2010/02/09/offerpal-media-lets-you-pay-for-games-by-putting-you-to-work", ],
      [ "2.9.2010", "Silicon Valley Business Journal", "Offerpal 'tasks' offers virtual currency through Amazon", "http://www.bizjournals.com/sanjose/stories/2010/02/08/daily26.html", ],
      [ "2.9.2010", "Virtual Worlds News", "Offerpal Partners With Amazon For Offerpal Tasks", "http://www.virtualgoodsnews.com/2010/02/offerpal-partners-with-amazon-for-offerpal-tasks.html", ],
      [ "2.9.2010", "Social Times", "Offerpal Announces New Way To Gain In-Game Virtual Currency: Online Tasks", "http://www.socialtimes.com/2010/02/offerpal-announces-new-way-to-gain-in-game-virtual-currency-online-tasks", ],
      [ "2.3.2010", "Business Week", "Facebook Games May Lead Payment Startups to $3.6 Billion Market", "http://www.businessweek.com/news/2010-02-03/facebook-games-may-lead-payment-startups-to-3-6-billion-market.html", ],
      [ "1.13.2010", "Inside Social Games", "Offerpal's Ads Go Live On Zynga Games, Now in Cafe World and Vampire Wars", "http://www.insidesocialgames.com/2010/01/13/offerpals-ads-go-live-on-zynga-games-now-in-cafe-world-and-vampire-wars/", ],
      [ "1.13.2010", "TechCrunch", "From Worst To First: Offerpal Drives Zynga's New Game Offers", "http://www.techcrunch.com/2010/01/13/zynga-offerpal-scamville/", ],
      [ "1.8.2010", "Computerworld", "Money for nothing? Virtual goods market takes off", "http://news.idg.no/cw/art.cfm?id=0FE5E4AD-1A64-6A71-CE2EB96397DA437F", ],
      [ "9.24.2009", "paidContent", "Digital Chocolate's Trip Hawkins: Offerpal Is Still A Good Partner For Social Game Companies", "http://paidcontent.org/article/419-digital-chocolates-trip-hawkins-offerpal-is-still-a-good-partner-for-so", ],
      [ "12.22.2009", "Inside Social Games", "Digital Chocolate Launches MMA Pro Fighter for Facebook", "http://www.insidesocialgames.com/2009/12/22/digital-chocolate-launches-mma-pro-fighter-for-facebook", ],
      [ "12.2.2009", "San Francisco Chronicle", "Offerpal moves to make social gaming offers more relevant, transparent", "http://www.sfgate.com/cgi-bin/blogs/techchron/detail?&entry_id=52745", ],
      [ "12.2.2009", "Virtual Worlds News", "Offerpal Introduces Offerpal Shopping", "http://www.virtualgoodsnews.com/2009/12/offerpal-introduces-offerpal-shopping.html", ],
      [ "12.2.2009", "VentureBeat", "Offerpal Media launches new reward system for gamers", "http://venturebeat.com/2009/12/02/offerpal-media-launches-new-reward-system-for-gamers/", ],
      [ "11.19.2009", "VentureBeat", "Offerpal Media sets standards to lock out scam offers", "http://venturebeat.com/2009/11/19/offerpal-media-sets-standards-to-lock-out-scam-offers/", ],
      [ "11.19.2009", "Silicon Valley Business Journal", "Offerpal issues ad guidelines", "http://sanjose.bizjournals.com/sanjose/stories/2009/11/16/daily86.html", ],
      [ "11.19.2009", "Social Times", "Offerpal Releases New Policies To Quell Critics", "http://www.socialtimes.com/2009/11/offerpal-releases-new-policies-to-quell-critics/", ],
      [ "11.19.2009", "MediaPost", "Offerpal Publishes New Ad Policies", "http://www.mediapost.com/publications/?fa=Articles.showArticle&art_aid=117755", ],
      [ "10.19.2009", "Fox News", "Virtual Money", "http://www.foxnews.com/video2/video08.html?maven_referralObject=10813444&maven_referralPlaylistId=&sRevUrl=http://www.foxnews.com/", ],
      [ "10.15.2009", "USA Today", "For social networks, it's game on", "http://www.usatoday.com/tech/gaming/2009-10-15-games-hit-social-networks_N.htm", ],
      [ "10.15.2009", "Fast Company", "EA Acquires Playfish, but Can It Compete on Facebook?", "http://www.fastcompany.com/blog/kevin-ohannessian/not-quite-conversation/ea-acquires-playfish-can-it-compete-facebook", ],
      [ "9.30.2009", "VentureBeat", "Offerpal: Game sites will make more money with its survey engine", "http://venturebeat.com/2009/09/30/offerpal-introduces-way-to-monetize-games-through-virtual-goods-and-surveys/", ],
      [ "9.30.2009", "Gamasutra", "Offerpal Releases Surveys Platform For Game Developers", "http://www.gamasutra.com/php-bin/news_index.php?story=25457", ],
      [ "9.24.2009", "Virtual Worlds News", "Engage! Expo 2009: Offers Hit Paydirt", "http://www.virtualworldsnews.com/2009/09/engage-expo-2009-offers-hit-paydirt.html", ],
      [ "9.22.2009", "Virtual Goods News", "Offerpal Partners with Zwinky's Mindspark Interactive", "http://www.virtualgoodsnews.com/2009/09/offerpal-partners-with-zwinkys-mindspark-interactive.html", ],
      [ "9.17.2009", "Virtual Goods News", "Offerpal Announces Multivariate Testing Platform", "http://www.virtualgoodsnews.com/2009/09/offerpal-announces-multivariate-testing-platform.html", ],
      [ "9.17.2009", "AllFacebook", "Offerpal Announces Multivariate Testing Platform", "http://www.allfacebook.com/2009/09/offerpal-launches-multivariate-testing-platform", ],
      [ "7.17.2009", "Gamasutra", "Offerpal Releases Security, Fraud Prevention Suite", "http://www.gamasutra.com/php-bin/news_index.php?story=24473", ],
      [ "7.16.2009", "Inside Social Games", "Offerpal Launches New Virtual Currency Anti-fraud System", "http://www.insidesocialgames.com/2009/07/16/offerpal-launches-new-virtual-currency-anti-fraud-system", ],
      [ "7.16.2009", "Social Times", "Offerpal Media Adds Fraud Detection to Make Virtual Currency Safer", "http://www.socialtimes.com/2009/07/offerpal-media-securit", ],
      [ "7.6.2009", "The Examiner", "Social gaming is a misnomer with real revenue potential", "http://www.examiner.com/x-4003-Techie-to-Trendy-Examiner~y2009m7d5-Social-gaming-a-misnomer-with-real-revenue-potential", ],
      [ "6.19.2009", "Inside Social Games", "Offerpal Adds Customizable Virtual Currency Analytics Tool", "http://www.insidesocialgames.com/2009/06/19/offerpal-adds-customizable-virtual-currency-analytics-tools", ],
      [ "6.19.2009", "Social Times", "Offerpal Adds Custom Analytics Platform to Virtual Economies", "http://www.socialtimes.com/2009/06/offerpal-adds-custom-analytics-platform-to-virtual-economies", ],
      [ "6.18.2009", "VentureBeat", "Offerpal adds analytics service to help game developers make money", "http://venturebeat.com/2009/06/18/offerpal-adds-game-analytics-for-making-money", ],
      [ "6.18.2009", "Virtual Goods News", "Offerpal Media Announces Virtual Currency Analytics Service", "http://www.virtualgoodsnews.com/2009/06/offerpal-media-announces-new-analytics-service.html", ],
      [ "6.9.2009", "VentureBeat", "Offerpal Media to help IMVU cash in on its virtual chat rooms", "http://venturebeat.com/2009/06/09/offerpal-media-to-help-imvu-to-cash-in-on-its-virtual-chat-rooms/", ],
      [ "6.9.2009", "Social Times", "Offerpal Media Teams with IMVU for More Social Ads", "http://www.socialtimes.com/2009/06/offerpal-media-teams-with-imvu-for-more-social-ads/", ],
      [ "6.9.2009", "InsideSocialGames", "IMVU Partners with Offerpal Media", "http://www.insidesocialgames.com/2009/06/09/imvu-partners-with-offerpal-media/", ],
      [ "6.9.2009", "Virtual Goods News", "Offerpal Brings Virtual Currency Offers To IMVU", "http://www.virtualgoodsnews.com/2009/06/offerpal-brings-virtual-currency-offers-to-imvu-.html", ],
      [ "6.2.2009", "Adotas", "Debunking The Myths of Social Media Advertising", "http://www.adotas.com/2009/06/debunking-the-myths-of-social-media-advertising/", ],
      [ "5.15.2009", "Silicon Valley/San Jose Business Journal", "Developers find booming business in the application world", "http://www.bizjournals.com/sanjose/stories/2009/05/18/focus3.html", ],
      [ "5.15.2009", "VentureBeat", "The top 12 trends of the video game industry", "http://venturebeat.com/2009/05/15/the-top-12-trends-of-the-video-game-industry", ],
      [ "4.18.2009", "Social Networking Watch", "Interview with Anu Shukla, CEO of Offerpal Media", "http://www.socialnetworkingwatch.com/2009/04/anu-shukla-ceo-of-offerpal.html", ],
      [ "3.30.2009", "Virtual Goods News", "Offerpal Brings Managed Offer Platform To OutSpark", "http://www.virtualgoodsnews.com/2009/03/offerpal-brings-managed-offer-platform-to-outspark.html", ],
      [ "3.30.2009", "Inside Social Games", "Offerpal Partners with Outspark, Aeria Games", "http://www.insidesocialgames.com/2009/03/30/offerpal-partners-with-outspark-aeria-games-on-offer-platform", ],
      [ "3.11.2009", "GigaOm", "MMORPG Network Aeria Partners With Offerpal", "http://gigaom.com/2009/03/11/aeria-partners-with-offerpal", ],
      [ "2.24.2009", "The Daily Anchor", "The Future of Social Media Advertising", "http://www.thedailyanchor.com/2009/02/24/the-future-of-social-media-advertising", ],
      [ "2.24.2009", "WebProNews", "Advertisers and Developers Monetize Social Media Apps", "http://www.thedailyanchor.com/2009/02/24/the-future-of-social-media-advertising", ],
      [ "2.20.2009", "San Francisco Chronicle", "Venture Capital Watch", "http://www.sfgate.com/cgi-bin/article.cgi?f=/c/a/2009/02/20/BUMK15VD4K.DTL&type=tech", ],
      [ "2.19.2009", "Worlds in Motion", " Interview: Offerpal Media's Anu Shukla On Monetizing Virtual Worlds With Advertising", "http://www.worldsinmotion.biz/2009/02/interview_offerpal_medias_anu.php", ],
      [ "2.18.2009", "MediaPost News", "Offerpal Media Raises $15 Million", "http://www.mediapost.com/publications/?fa=Articles.showArticle&art_aid=100481", ],
      [ "2.18.2009", "Adotas", "Offerpal Media picks up some cash", "http://www.adotas.com/2009/02/offerpal-media-picks-up-some-cash", ],
      [ "2.17.2009", "San Jose Business Journal", "Offerpal Media raises $15M in 2nd round", "http://sanjose.bizjournals.com/sanjose/stories/2009/02/16/daily21.html", ],
      [ "2.17.2009", "San Jose Mercury", "Money for Monetization", "http://www.mercurynews.com/business/ci_11723937", ],
      [ "2.17.2009", "Silicon Valley Wire", "Fremont-Based Offerpal Media Raises $15 Million in Second Round", "http://www.siliconvalleywire.com/svw/2009/02/fremont-based-offerpal-media-raises-15-million-in-second-round.html", ],
      [ "2.17.2009", "Silicon Tap", "Offerpal Gets $15M", "http://www.silicontap.com/offerpal_gets___m/s-0019969.html", ],
      [ "2.17.2009", "Cnet", "Webware Radar", "http://news.cnet.com/8301-17939_109-10165716-2.html?tag=mncol", ],
      [ "2.17.2009", "paidContent", "Offerpal Media Raises $15 Million For In-Game, Social Media Ads", "http://www.paidcontent.org/entry/419-offerpal-media-raises-15-million-for-virtual-goods-microtransactions", ],
      [ "2.17.2009", "Vator News", "Offerpal's offer scores", "http://vator.tv/news/show/2009-02-17-offerpals-offer-scores", ],
      [ "2.17.2009", "Digital Media Wire", "Social Media Ad Firm Offerpal Media Raises $15 Million", "http://www.dmwmedia.com/news/2009/02/17/social-media-ad-firm-offerpal-media-raises-$15-million", ],
      [ "2.17.2009", "Xconomy", "North Bridge in $15M OfferPal Round", "http://www.xconomy.com/boston/2009/02/17/north-bridge-in-15m-offerpal-round", ],
      [ "2.17.2009", "VentureWire", "Offerpal Funded To Help Social Web Make Money", "https://www.fis.dowjones.com/article.aspx?ProductIDFromApplication=32&aid=DJFVW00020090217e52h000e2&r=Rss&s=DJFVW", ],
      [ "2.17.2009", "GigaOm", "Offerpal's Virtual Money Service Gets $15M In Funding", "http://gigaom.com/2009/02/17/offerpals-virtual-money-service-gets-15m-in-funding", ],
      [ "2.17.2009", "Inside Facebook", "Offerpal Raises $15 Million Series B to Grow Offer Platform", "http://www.insidefacebook.com/2009/02/17/offerpal-raises-15-million-series-b-to-grow-offer-platform", ],
      [ "2.17.2009", "Virtual Good News", "Offerpal Secures $15 Million in Series B Venture Capital", "http://www.virtualgoodsnews.com/2009/02/offerpal-secures-15-million-in-series-b-venture-capital.html#more", ],
      [ "2.17.2009", "Marketing Shift", "Q&amp;A with Offerpal Media CEO Anu Shukla: Monetizing Social Network Apps", "http://www.marketingshift.com/2009/2/qa-offerpal-media-ceo-anu.cfm", ],
      [ "2.17.2009", "VentureBeat", "Offerpal Media raises $15 million for social monetization platform", "http://venturebeat.com/2009/02/17/offerpal-media-raises-15-million-for-social-monetization-platform", ],
      [ "2.17.2009", "Social Times", "Offerpal Gets $15M to Build Out Social Ads", "http://www.socialtimes.com/2009/02/offerpal-series", ],
      [ "2.17.2009", "Threepoint Networks Blog", "Your pal, Offerpal, Round 2 = $15 Million", "http://threepointnetworks.net/2009/02/17/your-pal-offerpal-round-2-15-million", ],
      [ "2.17.2009", "New World Notes", "What Second Life Entrepeneurs Can Learn From Offerpal", "http://nwn.blogs.com/nwn/2009/02/what-second-life-entrepeneurs-can-learn-from-offerpal.html", ],
      [ "2.17.2009", "Startup Meme", "Offerpal Media raises $15 million in Series B", "http://startupmeme.com/offerpal-media-raises-15-million-in-series-b", ],
      [ "2.17.2009", "New York Times", "Offerpal Media Raises $15 Million  to Peddle In-Game Ads", "http://bits.blogs.nytimes.com/2009/02/17/offerpal-media-raises-15-million-to-peddle-in-game-ads/", ],
      [ "1.23.2009", "Offerpal Media Named AlwaysOn OnMedia 100 Winner", "Offerpal Media Named AlwaysOn OnMedia 100 Winner", "http://www.offerpalmedia.com/OnMeida_Review.php", ],
      [ "1.13.2009", "Apple iPhone", "Offerpal Launches Monetization Platform for the Apple iPhone", "http://www.offerpalmedia.com/apple_iphone.php", ],
      [ "12.18.2008", "Mashable", "Beyond Facebook Gifts: Virtual Currencies 101", "http://mashable.com/2008/12/18/virtual-currency/", ],
      [ "11.25.2008", "InsideFacebook", "10 Tips for Monetizing Social Traffic Through Virtual Currency", "http://www.insidefacebook.com/2008/11/25/10-tips-for-monetizing-social-traffic-through-virtual-currency/", ],
      [ "9.4.2008", "Social Times", "Offerpal Launches MySpace \"Onboarding\" Feature", "http://www.offerpalmedia.com/onboarding.php", ],
      [ "9.4.2008", "InsideFacebook", "Half of Offerpal Media's Business is Now in MySpace Apps", "http://www.insidefacebook.com/2008/09/04/half-of-offerpal-medias-business-is-now-in-myspace-apps/", ],
      [ "9.3.2008", "VentureBeat", "Offerpal Launches Game Monetization Service for MySpace", "http://www.offerpalmedia.com/game_monetization.php", ],
      [ "8.25.2008", "TechCrunch", "Can You Guess Which Facebook App Is Making A Million Dollars A Month?", "http://www.offerpalmedia.com/tech-crunch.php", ],
      [ "8.8.2008", "Silicon Alley Insider", "MySpace Apps Catching Up To Facebook's?", "http://www.alleyinsider.com/2008/8/myspace-apps-catching-up-to-facebook-s-", ],
      [ "6.5.2008", "InsideFacebook", "Offerpal Media Monetizing Virtual Currency Apps on Facebook", "http://www.insidefacebook.com/2008/06/05/offerpal-media-monetizing-virtual-currency-apps-on-facebook/", ],
    ]
  end
end

class PressHaml
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  def press_contact(person)
    unless person == :tapjoy || person == :media
      "<p class='contact'>#{person[:name]}<br/>#{person[:company]}<br/>#{person[:phone]}<br/>#{mail_to(person[:email])}<br/><br/></p>"
    end
  end

  def link_to_tapjoy
    '<a href="https://www.tapjoy.com/">www.tapjoy.com</a>'
  end

  def link_to_offerpal(text='www.offerpalmedia.com')
    "<a href=\"http://www.offerpalmedia.com\">#{text}</a>"
  end
end
