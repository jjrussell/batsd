class QueueNames
  BASE_NAME = "#{AWS.config.use_ssl ? 'https://' : 'http://'}#{AWS.config.sqs_endpoint}/#{AWS_ACCOUNT_ID}/#{RUN_MODE_PREFIX}"

  APP_STATS_DAILY            = "#{BASE_NAME}AppStatsDaily"
  APP_STATS_HOURLY           = "#{BASE_NAME}AppStatsHourly"
  CALCULATE_SHOW_RATE        = "#{BASE_NAME}CalculateShowRate"
  CONVERSION_TRACKING        = "#{BASE_NAME}ConversionTracking"
  CREATE_CONVERSIONS         = "#{BASE_NAME}CreateConversions"
  CONVERSION_NOTIFICATIONS   = "#{BASE_NAME}ConversionNotifications"
  CREATE_DEVICE_IDENTIFIERS  = "#{BASE_NAME}CreateDeviceIdentifiers"
  CREATE_INVOICES            = "#{BASE_NAME}CreateInvoices"
  DOWNLOADS                  = "#{BASE_NAME}Downloads"
  FAILED_DOWNLOADS           = "#{BASE_NAME}FailedDownloads"
  FAILED_EMAILS              = "#{BASE_NAME}FailedEmails"
  FAILED_SDB_SAVES           = "#{BASE_NAME}FailedSdbSaves"
  GET_STORE_INFO             = "#{BASE_NAME}GetStoreInfo"
  MAIL_CHIMP_UPDATES         = "#{BASE_NAME}MailChimpUpdates"
  PARTNER_CHANGES            = "#{BASE_NAME}PartnerChanges"
  PARTNER_NOTIFICATIONS      = "#{BASE_NAME}PartnerNotifications"
  RECOUNT_STATS              = "#{BASE_NAME}RecountStats"
  RESOLVE_SUPPORT_REQUESTS   = "#{BASE_NAME}ResolveSupportRequests"
  SDB_BACKUPS                = "#{BASE_NAME}SdbBackups"
  SELECT_VG_ITEMS            = "#{BASE_NAME}SelectVgItems"
  SEND_CURRENCY              = "#{BASE_NAME}SendCurrency"
  SUSPICIOUS_GAMERS          = "#{BASE_NAME}SuspiciousGamers"
  TERMINATE_NODES            = "#{BASE_NAME}TerminateNodes"
  THIRD_PARTY_TRACKING       = "#{BASE_NAME}ThirdPartyTracking"
  UDID_REPORTS               = "#{BASE_NAME}UdidReports"
  UPDATE_MONTHLY_ACCOUNT     = "#{BASE_NAME}UpdateMonthlyAccount"
  SEND_WELCOME_EMAILS        = "#{BASE_NAME}SendWelcomeEmails"
  SEND_WELCOME_EMAILS_OLD    = "#{BASE_NAME}SendWelcomeEmailsOld"
  UPDATE_PAPAYA_DEVICES      = "#{BASE_NAME}UpdatePapayaDevices"
  UPDATE_PAPAYA_USER_COUNT   = "#{BASE_NAME}UpdatePapayaUserCount"
  RECORD_UPDATES             = "#{BASE_NAME}RecordUpdates"
  CACHE_OPTIMIZED_OFFER_LIST = "#{BASE_NAME}CacheOptimizedOfferList"
  SEND_COUPON_EMAILS         = "#{BASE_NAME}SendCouponEmails"
  CACHE_RECORD_NOT_FOUND     = "#{BASE_NAME}CacheRecordNotFound"
end
