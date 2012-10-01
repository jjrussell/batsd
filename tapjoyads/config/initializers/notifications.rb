case Rails.env
when "test"
	Tapjoyad::Application.config.notifications_url = 'http://localhost:5000'
	NotificationsClient.set_notifications_host("http://localhost:5000")
	Tapjoyad::Application.config.signage_secret = ENV['SIGNAGE_SECRET']	
when "development"
	Tapjoyad::Application.config.notifications_url = 'http://localhost:5000'
	NotificationsClient.set_notifications_host("http://localhost:5000")
	Tapjoyad::Application.config.signage_secret = ENV['SIGNAGE_SECRET']
when "production"
	Tapjoyad::Application.config.notifications_url = 'notifications.tapjoy.com'
	NotificationsClient.set_notifications_host("notifications.tapjoy.com")
	Tapjoyad::Application.config.signage_secret = ENV['SIGNAGE_SECRET']
when "staging"
	Tapjoyad::Application.config.notifications_url = 'qa.notifications.tapjoy.com'
	NotificationsClient.set_notifications_host("qa.notifications.tapjoy.com")
	Tapjoyad::Application.config.signage_secret = ENV['SIGNAGE_SECRET']
qa.notifications.tapjoy.com	
end
