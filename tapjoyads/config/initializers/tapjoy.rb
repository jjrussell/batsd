require 'extensions'
require 'notifier'

GEOIP = GeoIP.new("#{Rails.root}/data/GeoIPCity.dat")
BANNED_IPS = Set.new(['174.120.96.162', '151.197.180.227', '74.63.224.218', '65.19.143.2'])

UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
APP_ID_FOR_DEVICES_REGEX = /^(\w|\.|-)*$/

MASTER_HEALTHZ_FILE = "#{Rails.root}/tmp/master_healthz_status.txt"

# SDK URLs
ANDROID_CONNECT_SDK         = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectSDK_Android_v8.1.7.zip'
ANDROID_OFFERS_SDK          = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyPublisherSDK_Android_v8.1.7.zip'
ANDROID_VG_SDK              = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyVirtualGoodsSDK_Android_v8.1.7.zip'
ANDROID_UNITY_PLUGIN        = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyUnityPlugin_Android_v8.1.7.zip'
ANDROID_PHONEGAP_PLUGIN     = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyPhoneGapPlugin_Android_v8.1.7.zip'
ANDROID_MARMALADE_EXTENSION = 'https://github.com/downloads/marmalade/Tapjoy-for-Marmalade/Tapjoy_Android.zip'

IPHONE_CONNECT_SDK         = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectSDK_iOS_v8.1.7.zip'
IPHONE_OFFERS_SDK          = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectPublisherSDK_iOS_v8.1.7.zip'
IPHONE_VG_SDK              = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectVirtualGoodsSDK_iOS_v8.1.7.zip'
IPHONE_UNITY_PLUGIN        = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectUnityPluginSample_v8.1.7.zip'
IPHONE_PHONEGAP_PLUGIN     = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyConnectPhoneGapPluginSample_v8.1.6.zip'
IPHONE_MARMALADE_EXTENSION = 'https://github.com/downloads/marmalade/Tapjoy-for-Marmalade/Tapjoy_iOS.zip'

WINDOWS_CONNECT_SDK = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyAdvertiserSDK_Windows_v2.0.0.zip'
WINDOWS_OFFERS_SDK  = 'https://s3.amazonaws.com/tapjoy/sdks/TapjoyPublisherSDK_Windows_v2.0.0.zip'

SDKLESS_MIN_LIBRARY_VERSION = '8.2.0'

DEV_FORUM_URL = 'https://groups.google.com/group/tapjoy-developer'
KNOWLEDGE_CENTER_URL = 'http://knowledge.tapjoy.com/'
TAPJOY_GAMES_REGISTRATION_OFFER_ID = 'f7cc4972-7349-42dd-a696-7fcc9dcc2d03'
TAPJOY_GAMES_CURRENT_TOS_VERSION = 2
TAPJOY_PARTNER_ID = '70f54c6d-f078-426c-8113-d6e43ac06c6d'
RECEIPT_EMAIL = 'email.receipts@tapjoy.com'
GAMES_ANDROID_MARKET_URL = 'https://play.google.com/store/apps/details?id=com.tapjoy.tapjoy'

WEB_REQUEST_LOGGER = SyslogLogger.new("#{RUN_MODE_PREFIX}rails-web_requests")

Mc.cache.flush if CLEAR_MEMCACHE

AWS.config(
  :access_key_id     => ENV['AWS_ACCESS_KEY_ID'],
  :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
  :http_handler      => AWS::Core::Http::HTTPartyHandler.new
)

GAMES_CONFIG = YAML::load_file("#{Rails.root}/config/games.yaml")[Rails.env]
MARKETPLACE_CONFIG = YAML::load_file("#{Rails.root}/config/marketplace.yaml")[Rails.env]

VERTICA_CONFIG = YAML::load_file("#{Rails.root}/config/vertica.yml")[Rails.env]

TEXTFREE_PUB_APP_ID = '6b69461a-949a-49ba-b612-94c8e7589642'

BLANK_IMAGE = 'data:image/gif;base64,R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=='

JAN_PARTNERS_TO_FIX = [
  ['15e8f471-7652-4b8a-9f4d-2da61cb84c60',  14444.69],
  ['1920b3c4-079d-4f90-a95e-ddeb9fe1ec27',  6929.64],
  ['28239536-44dd-417f-942d-8247b6da0e84',  6579.45],
  ['64e40a83-4724-4ba4-9b38-1c8ca906777a',  6187.56],
  ['b58c3aa3-6766-4cd5-8545-7d96e72205e0',  5660.92],
  ['3b5406d8-9c1b-4e51-a806-66dae10830a5',  5623.89],
  ['6f41713e-ed13-4cc4-9bff-b7ce1074d4bf',  5107.64],
  ['a2713645-7c13-4a24-b1cb-6c0974e826a9',  4223.25],
  ['d0aa7661-b18c-4f53-aa4e-7276aedba69d',  4100.37],
  ['ce059644-18a0-4f27-bc2b-c2a2d4d4e7bf',  4036.13],
  ['db315ada-ffb8-4e84-b781-8420cf3553e4',  3502.88],
  ['431c32a2-7660-4819-a6a6-f2b2b524e611',  3122.18],
  ['285e9d96-bc53-4071-9e94-953f358df139',  3096.32],
  ['e9afc259-3e6e-4463-8aea-23e4237e7b3f',  2817.48],
  ['d7a5ddb1-46d6-495a-827e-ef099adde0d3',  2481.12],
  ['443721a9-e426-47de-948c-658a558744bc',  2109.12],
  ['d0540fa5-3dff-490c-b7e6-ed480ad80b2f',  2049.65],
  ['20e0f227-7a66-48d1-b001-c5055d2a891e',  1720.23],
  ['6c95154c-a7df-4122-838e-ff8cceef17be',  1513.60],
  ['362e6c78-96a2-4b71-b218-a47743310eaf',  1488.78],
  ['5ffb4913-dca9-44e3-9461-7b3fea1a39c3',  1306.50],
  ['1aaadc24-0164-41c4-a898-1f2ca6b809ce',  1160.00],
  ['9c36735f-fa29-4fc7-96bb-9293febb8fee',  1149.85],
  ['da76ddbf-9ad2-4cfb-a8fe-1efe1f073e96',  1096.19],
  ['126414b0-27ec-4782-8c5c-10a54953ef82',  1063.44]]

DEC_PARTNERS_TO_FIX = [
  ['64e40a83-4724-4ba4-9b38-1c8ca906777a',  22406.46 ],
  ['15e8f471-7652-4b8a-9f4d-2da61cb84c60',  18338.37 ],
  ['1920b3c4-079d-4f90-a95e-ddeb9fe1ec27',  13552.96 ],
  ['6f41713e-ed13-4cc4-9bff-b7ce1074d4bf',  10342.48 ],
  ['3b5406d8-9c1b-4e51-a806-66dae10830a5',  10285.72 ],
  ['238218eb-7813-4f78-a885-91c064f26d56',  9976.26  ],
  ['8ddb5d8c-44cc-479b-baaf-b6b81ac98f27',  8580.60  ],
  ['4149425a-33d5-42a3-a8ed-fc7edc65365d',  8575.65  ],
  ['d0aa7661-b18c-4f53-aa4e-7276aedba69d',  8514.10  ],
  ['b58c3aa3-6766-4cd5-8545-7d96e72205e0',  8393.99  ],
  ['6e37abc1-b356-4a19-9eda-1d126500b84e',  8351.66  ],
  ['d7a5ddb1-46d6-495a-827e-ef099adde0d3',  6366.54  ],
  ['a2713645-7c13-4a24-b1cb-6c0974e826a9',  5605.35  ],
  ['126414b0-27ec-4782-8c5c-10a54953ef82',  5604.97  ],
  ['f2b5ae99-cd46-4b3c-ad27-6d8f12f60ccf',  5326.77  ],
  ['28239536-44dd-417f-942d-8247b6da0e84',  5083.25  ],
  ['a1f89aea-5b12-47be-91c0-d92ec862052b',  4958.56  ],
  ['e9c32d0c-7f84-44ea-92e3-520f4a5c8384',  4853.00  ],
  ['4cd38e44-cb8e-4fa2-bf03-fbae12587027',  4456.08  ],
  ['cc9d24b2-bbd5-4ba6-97dc-90da74031660',  4363.12  ],
  ['db315ada-ffb8-4e84-b781-8420cf3553e4',  4239.33  ],
  ['ce059644-18a0-4f27-bc2b-c2a2d4d4e7bf',  4172.34  ],
  ['285e9d96-bc53-4071-9e94-953f358df139',  4107.76  ],
  ['8031c3a5-fb44-4b7e-aa3c-db32f154196b',  3978.38  ],
  ['bccbd300-cbc2-4930-a0ff-f77b9563dd66',  3972.94  ],
  ['4b0b203b-2ca6-402c-b86a-f50beb71fe31',  3752.24  ],
  ['424f9287-c27e-44e7-b438-3d067b71d7da',  3629.26  ],
  ['2a4787f9-9d70-4523-b2a5-54a4108a2811',  3217.33  ],
  ['b917d257-952e-4a6f-a8fd-0a7fcf7a57e9',  3198.92  ],
  ['80cfb8ac-f160-4656-a4a0-8e87fdc97a43',  3079.31  ],
  ['62db9fd3-1035-4c45-9575-5fcb56b9396f',  3059.72  ],
  ['362e6c78-96a2-4b71-b218-a47743310eaf',  3007.22  ],
  ['8fc62803-3751-48c0-ab12-0a8b51469c10',  2854.92  ],
  ['971b93a6-c221-4d59-9b8c-bbf603ed68d5',  2809.00  ],
  ['443721a9-e426-47de-948c-658a558744bc',  2768.55  ],
  ['ca413c9b-c1a5-4b53-8a6e-92bad54b5636',  2585.75  ],
  ['8dd71f55-3ee5-47ab-aea1-219e3b053c3c',  2507.15  ],
  ['9d60337b-f942-448e-adb9-6d23b15fad15',  2500.80  ],
  ['1aaadc24-0164-41c4-a898-1f2ca6b809ce',  2487.84  ],
  ['d0540fa5-3dff-490c-b7e6-ed480ad80b2f',  2295.04  ],
  ['20e0f227-7a66-48d1-b001-c5055d2a891e',  2257.95  ],
  ['be048501-1161-4977-ba1a-58ad48ea2f7c',  2075.17  ],
  ['6534151d-f14c-43ed-80b2-741c670b4442',  2031.32  ],
  ['6c95154c-a7df-4122-838e-ff8cceef17be',  2021.50  ],
  ['da76ddbf-9ad2-4cfb-a8fe-1efe1f073e96',  1920.64  ],
  ['431c32a2-7660-4819-a6a6-f2b2b524e611',  1851.24  ],
  ['5ffb4913-dca9-44e3-9461-7b3fea1a39c3',  1701.41  ],
  ['9c36735f-fa29-4fc7-96bb-9293febb8fee',  1587.46  ],
  ['d0886f36-c9a3-436a-b697-0cee1aada22f',  1585.85  ],
  ['e9afc259-3e6e-4463-8aea-23e4237e7b3f',  1484.80  ],
  ['1538ee84-b862-41bf-9cbb-3740c7d0da08',  1435.54  ],
  ['f00c4705-dfde-4b8f-8af5-a7e7501e738b',  1334.24  ],
  ['47f2bf91-975f-450b-9267-7ab692473dec',  1226.33  ],
  ['ea98b435-30a0-422f-b4b3-cd27dd8b626c',  1225.72  ],
  ['36c47eb5-3c1b-4004-b562-3b06a9efdfc9',  1213.24  ],
  ['54cfba4c-c808-4728-b7d9-9047dc37eb77',  1132.45  ]]

PARTNERS_TO_MESSAGE = (JAN_PARTNERS_TO_FIX + DEC_PARTNERS_TO_FIX).collect(&:first).to_set
