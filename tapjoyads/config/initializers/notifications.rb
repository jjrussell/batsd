notifications = YAML::load_file("#{Rails.root}/config/notifications.yaml")[Rails.env]

Tapjoyad::Application.config.notifications_url = notifications['url']
NotificationsClient.set_host(notifications['url'])
NotificationsClient.set_secret(notifications['notifications_secret'])
Tapjoyad::Application.config.notifications_secret = notifications['notifications_secret']
