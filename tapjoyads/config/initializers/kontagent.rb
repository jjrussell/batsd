require 'kontagent'
KT_CONFIG = YAML.load_file("#{Rails.root}/config/kontagent.yml")[Rails.env]
Kontagent::Base.configure(KT_CONFIG)

KontagentConfig = OpenStruct.new
KontagentConfig.partner = KT_CONFIG['partner']
KontagentConfig.domain = KT_CONFIG['domain']
