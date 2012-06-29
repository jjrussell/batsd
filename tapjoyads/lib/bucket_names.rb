class BucketNames
  ADIMAGES            = RUN_MODE_PREFIX + 'adimages'
  CONVERSION_ARCHIVES = RUN_MODE_PREFIX + 'conversion-archives'
  FAILED_SDB_SAVES    = RUN_MODE_PREFIX + 'failed-sdb-saves-generic'
  FAILED_SQS_WRITES   = RUN_MODE_PREFIX + 'failed-sqs-writes'
  OFFER_DATA          = RUN_MODE_PREFIX + 'offer-data'
  PUBLISHER_ADS       = RUN_MODE_PREFIX + 'publisher-ads'
  SDB_BACKUPS         = RUN_MODE_PREFIX + 'sdb-backups'
  STATS               = RUN_MODE_PREFIX + 'tj-stats'
  STORE_CLICKS        = RUN_MODE_PREFIX + 'store-clicks'
  STORE_RANKS         = RUN_MODE_PREFIX + 'store-ranks'
  SUPPORT_REQUESTS    = RUN_MODE_PREFIX + 'support-requests'
  APP_SCREENSHOTS     = Rails.env.production? ? 'app-screenshots.tapjoy.com' : RUN_MODE_PREFIX + 'app-screenshots'
  TAPJOY              = RUN_MODE_PREFIX + 'tapjoy'
  TAPJOY_DOCS         = RUN_MODE_PREFIX + 'tj-docs'
  TAPJOY_GAMES        = RUN_MODE_PREFIX + 'tj-games'
  OPTIMIZATION        = RUN_MODE_PREFIX + 'tj-optimization'
  OPTIMIZATION_CACHE  = RUN_MODE_PREFIX + 'tj-optimization-cache'
  UDID_REPORTS        = RUN_MODE_PREFIX + 'udid-reports'
  VIRTUAL_GOODS       = RUN_MODE_PREFIX + 'virtual_goods'
  WEB_REQUESTS        = RUN_MODE_PREFIX + 'web-requests'
end
