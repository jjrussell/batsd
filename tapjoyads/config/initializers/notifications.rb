case Rails.env
when "test"
	Tapjoyad::Application.config.notifications_url = 'notifications.tapjoy.com'
	NotificationsClient.set_notifications_host("notifications.tapjoy.com")
	Tapjoyad::Application.config.gcm_api_key =  ENV['GCM_KEY']
	Tapjoyad::Application.config.signage_secret = ENV['SIGNAGE_SECRET']	
when "development"
	Tapjoyad::Application.config.notifications_url = 'notifications.tapjoy.com'
	NotificationsClient.set_notifications_host("notifications.tapjoy.com")
	Tapjoyad::Application.config.gcm_api_key =  ENV['GCM_KEY']
	Tapjoyad::Application.config.signage_secret = ENV['SIGNAGE_SECRET']
when "production"
	Tapjoyad::Application.config.notifications_url = 'http://localhost:5000'
	NotificationsClient.set_notifications_host("http://localhost:5000")
	Tapjoyad::Application.config.gcm_api_key = ENV['GCM_KEY']
	Tapjoyad::Application.config.signage_secret = ENV['SIGNAGE_SECRET']
end
