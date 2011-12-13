class QueueNames
  BASE_NAME = "#{AWS.config.use_ssl ? 'https://' : 'http://'}#{AWS.config.sqs_endpoint}/#{AWS_ACCOUNT_ID}/#{RUN_MODE_PREFIX}"

  APP_STATS_DAILY        = "#{BASE_NAME}AppStatsDaily"
  APP_STATS_HOURLY       = "#{BASE_NAME}AppStatsHourly"
  CALCULATE_SHOW_RATE    = "#{BASE_NAME}CalculateShowRate"
  CONVERSION_TRACKING    = "#{BASE_NAME}ConversionTracking"
  CREATE_CONVERSIONS     = "#{BASE_NAME}CreateConversions"
  CREATE_INVOICES        = "#{BASE_NAME}CreateInvoices"
  FAILED_DOWNLOADS       = "#{BASE_NAME}FailedDownloads"
  FAILED_EMAILS          = "#{BASE_NAME}FailedEmails"
  FAILED_SDB_SAVES       = "#{BASE_NAME}FailedSdbSaves"
  GET_STORE_INFO         = "#{BASE_NAME}GetStoreInfo"
  MAIL_CHIMP_UPDATES     = "#{BASE_NAME}MailChimpUpdates"
  PARTNER_CHANGES        = "#{BASE_NAME}PartnerChanges"
  PARTNER_NOTIFICATIONS  = "#{BASE_NAME}PartnerNotifications"
  RECOUNT_STATS          = "#{BASE_NAME}RecountStats"
  SDB_BACKUPS            = "#{BASE_NAME}SdbBackups"
  SELECT_VG_ITEMS        = "#{BASE_NAME}SelectVgItems"
  SEND_CURRENCY          = "#{BASE_NAME}SendCurrency"
  UDID_REPORTS           = "#{BASE_NAME}UdidReports"
  UPDATE_MONTHLY_ACCOUNT = "#{BASE_NAME}UpdateMonthlyAccount"
end
