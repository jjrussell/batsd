case Rails.env
when "development"
	Tapjoyad::Application.config.notifications_url = 'notifications.tapjoy.com'
	NotificationsClient.set_notifications_host("notifications.tapjoy.com")
when "production"
	Tapjoyad::Application.config.notifications_url = 'http://localhost:5000'
	NotificationsClient.set_notifications_host("http://localhost:5000")
end
