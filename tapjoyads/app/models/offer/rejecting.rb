module Offer::Rejecting

  NON_LIMITED_CURRENCY_IDS = Set.new(['127095d1-42fc-480c-a65d-b5724003daf0', '91631942-cfb8-477a-aed8-48d6ece4a23f', 'e3d2d144-917e-4c5b-b64f-0ad73e7882e7', 'b9cdd8aa-632d-4633-866a-0b10d55828c0'])

  ALREADY_COMPLETE_IDS = {
    # Tap Farm
    [ '4ddd4e4b-123c-47ed-b7d2-7e0ff2e01424' ] => [ '4ddd4e4b-123c-47ed-b7d2-7e0ff2e01424', 'bad4b0ae-8458-42ba-97ba-13b302827234', '403014c2-9a1b-4c1d-8903-5a41aa09be0e' ],
    # Tap Store
    [ 'b23efaf0-b82b-4525-ad8c-4cd11b0aca91' ] => [ 'b23efaf0-b82b-4525-ad8c-4cd11b0aca91', 'a994587c-390c-4295-a6b6-dd27713030cb', '6703401f-1cb2-42ec-a6a4-4c191f8adc27' ],
    # Clubworld
    [ '3885c044-9c8e-41d4-b136-c877915dda91' ] => [ '3885c044-9c8e-41d4-b136-c877915dda91', 'a3980ac5-7d33-43bc-8ba1-e4598c7ed279' ],
    # Groupon iOS Apps
    [ '7f44c068-6fa1-482c-b2d2-770edcf8f83d', '192e6d0b-cc2f-44c2-957c-9481e3c223a0', '05d8d649-766a-40d2-9fc3-1009307ff966', 'a07cfeda-8f35-4490-99ea-f75ee7463fa4' ] => [ '7f44c068-6fa1-482c-b2d2-770edcf8f83d', '192e6d0b-cc2f-44c2-957c-9481e3c223a0', '05d8d649-766a-40d2-9fc3-1009307ff966', 'a07cfeda-8f35-4490-99ea-f75ee7463fa4' ],
    # Groupon iOS ActionOffers
    [ 'a13bd597-183a-41ce-a6e1-48797e61be9d', 'aa136cec-6241-4cb9-b790-e8ed1532f64e', '43a65418-3863-42b5-80fc-ea4b02828db2' ] => [ 'a13bd597-183a-41ce-a6e1-48797e61be9d', 'aa136cec-6241-4cb9-b790-e8ed1532f64e', '43a65418-3863-42b5-80fc-ea4b02828db2' ],
    # Groupon Android Apps
    [ '3368863b-0c69-4a54-8a14-2ec809140d8f', 'bbadbb72-4f96-49e3-90b8-fb45a82b195e' ] => [ '3368863b-0c69-4a54-8a14-2ec809140d8f', 'bbadbb72-4f96-49e3-90b8-fb45a82b195e' ],
    # My Town 2
    [ 'cab56716-8e27-4a4c-8477-457e1d311209', '069eafb8-a9b8-4293-8d2a-e9d9ed659ac8' ] => [ 'cab56716-8e27-4a4c-8477-457e1d311209', '069eafb8-a9b8-4293-8d2a-e9d9ed659ac8' ],
    # Snoopy's Street Fair
    [ '99d4a403-38a8-41e3-b7a2-5778acb968ef', 'b22f3ef8-947f-4605-a5bc-a83609af5ab7' ] => [ '99d4a403-38a8-41e3-b7a2-5778acb968ef', 'b22f3ef8-947f-4605-a5bc-a83609af5ab7' ],
    # Zombie Lane
    [ 'd299fb80-29f6-48a3-8957-bbd8a20acdc9', 'eca4615a-7439-486c-b5c3-efafe3ec69a6' ] => [ 'd299fb80-29f6-48a3-8957-bbd8a20acdc9', 'eca4615a-7439-486c-b5c3-efafe3ec69a6' ],
    # iTriage
    [ '7f398870-b1da-478f-adfb-82d22d25c13d', '6f7d9238-be52-46e9-902b-5ad038ddb7eb' ] => [ '7f398870-b1da-478f-adfb-82d22d25c13d', '6f7d9238-be52-46e9-902b-5ad038ddb7eb' ],
    # Intuit GoPayment
    [ 'e8cca05a-0ec0-41fd-9820-24e24db6eec4', 'b1a1b737-bc9d-4a0b-9587-a887d22ae356' ] => [ 'e8cca05a-0ec0-41fd-9820-24e24db6eec4', 'b1a1b737-bc9d-4a0b-9587-a887d22ae356' ],
    # Hotels.com
    [ '6b714133-2358-4918-842d-f266abe6b7b5', 'eaa1cfc9-3499-49ce-8f03-092bcc0ce77a' ] => [ '6b714133-2358-4918-842d-f266abe6b7b5', 'eaa1cfc9-3499-49ce-8f03-092bcc0ce77a' ],
    # Trulia Real Estate
    [ 'afde4da8-3943-44fd-a901-08be5470eaa4', '2ff9ad4e-58a2-417b-9333-d65835b71049' ] => [ 'afde4da8-3943-44fd-a901-08be5470eaa4', '2ff9ad4e-58a2-417b-9333-d65835b71049' ],
    # Social Girl
    [ '7df94075-16c9-4c6a-a170-50e1e8fc9991', '3712bd73-eda2-4ca9-934a-3465cf38ef35' ] => [ '7df94075-16c9-4c6a-a170-50e1e8fc9991', '3712bd73-eda2-4ca9-934a-3465cf38ef35' ],
    # Top Girl
    [ 'c7b2a54e-8faf-4959-86ab-e862473c9dd4', '9f47822c-2183-4969-98b1-ce64430e4e58' ] => [ 'c7b2a54e-8faf-4959-86ab-e862473c9dd4', '9f47822c-2183-4969-98b1-ce64430e4e58' ],
    # Saving Star
    [ 'c2ef96ba-5c6b-4479-bffa-9b1beca08f1b', '1d63a4fa-82ed-4442-955c-ef0d75978fad', '0ba2a533-d26d-4953-aa3e-fd01187e30e1' ] => [ 'c2ef96ba-5c6b-4479-bffa-9b1beca08f1b', '1d63a4fa-82ed-4442-955c-ef0d75978fad', '0ba2a533-d26d-4953-aa3e-fd01187e30e1' ],
    # Flirtomatic iOS
    [ 'bb26407e-6713-4b67-893d-4b47242f1ce0', '23fed671-4558-4c2e-8ceb-dcb41399c5d7',
      '398a71ee-5157-4975-aabb-f7fa5a48ed7f', 'd5769336-acd4-4d25-9483-f84512247b7a',
      'b8dfb746-ceba-44af-814b-d04231afcc11' ] => [ 'bb26407e-6713-4b67-893d-4b47242f1ce0',
      '23fed671-4558-4c2e-8ceb-dcb41399c5d7', '398a71ee-5157-4975-aabb-f7fa5a48ed7f',
      'd5769336-acd4-4d25-9483-f84512247b7a', 'b8dfb746-ceba-44af-814b-d04231afcc11' ],
    # Credit Sesame
    [ 'e13d1e07-9770-4d71-a9ba-fa42fd8df519', 'a3abde4d-7eff-49c7-8079-85d2c5238e88' ] => [ 'e13d1e07-9770-4d71-a9ba-fa42fd8df519', 'a3abde4d-7eff-49c7-8079-85d2c5238e88' ],
    # Play Up
    [ 'de54dbd2-71ff-405e-86f6-f680dcffe8d7', '02c569fc-4a3b-4807-897d-70fad43ae64a' ] => [ 'de54dbd2-71ff-405e-86f6-f680dcffe8d7', '02c569fc-4a3b-4807-897d-70fad43ae64a' ],
    # Priceline
    [ 'b64dba85-9cf9-4e14-b991-f3b7574880c7', '70d3de82-3062-4f19-8864-e453d8b9ee35' ] => [ 'b64dba85-9cf9-4e14-b991-f3b7574880c7', '70d3de82-3062-4f19-8864-e453d8b9ee35' ],
    # Gamefly
    [ 'ac845f34-6631-45f4-8d7e-8d9d981c05b4', '0c785af7-57b8-4efe-9112-44c7194f5a94' ] => [ 'ac845f34-6631-45f4-8d7e-8d9d981c05b4', '0c785af7-57b8-4efe-9112-44c7194f5a94' ],
    # Zillow
    [ '11bf4c4e-0a00-4536-b029-cf455f4976c0', 'd1d5ec4c-ec7d-490b-a1e0-76af0967de53', 'a9ef5dfe-4182-4208-ba75-dd93e18d32be' ] =>
    [ '11bf4c4e-0a00-4536-b029-cf455f4976c0', 'd1d5ec4c-ec7d-490b-a1e0-76af0967de53', 'a9ef5dfe-4182-4208-ba75-dd93e18d32be' ],
    # Mobile Xpression
    [ '49cbc1ae-8f04-4220-b0b8-d23a1559a560', '9007b2c0-6e26-46df-8950-ade2250e6167' ] => [ '49cbc1ae-8f04-4220-b0b8-d23a1559a560', '9007b2c0-6e26-46df-8950-ade2250e6167' ],
    # Cool Savings
    [ 'acc8406a-2bdf-4800-a981-b9dc05493cef', '1d135d70-5eae-4d57-9131-febea19d9ea7' ] => [ 'acc8406a-2bdf-4800-a981-b9dc05493cef', '1d135d70-5eae-4d57-9131-febea19d9ea7' ],
    # Card Ace Casino HD
    [ '6ece54bb-b4f0-40fa-9d8c-b5425eb43dc7', '04ef8af7-f3ab-4062-b20c-1c20609302aa', '2d880990-563d-4612-bef1-e8b492f29d1b', 'b132b5b3-c68b-42ef-b809-bb43ada6be47', 'cfed8dfe-4b53-45e2-90c7-93587b4f4a5a' ] =>
    [ '6ece54bb-b4f0-40fa-9d8c-b5425eb43dc7', '04ef8af7-f3ab-4062-b20c-1c20609302aa', '2d880990-563d-4612-bef1-e8b492f29d1b', 'b132b5b3-c68b-42ef-b809-bb43ada6be47', 'cfed8dfe-4b53-45e2-90c7-93587b4f4a5a' ],
    # Card Ace Casino
    [ 'a64fafc9-78a0-443b-b8f1-e368d8f7c5da', '495234c6-4b83-442b-ac2a-78205e9e4064' ] =>
    [ 'a64fafc9-78a0-443b-b8f1-e368d8f7c5da', '495234c6-4b83-442b-ac2a-78205e9e4064' ],
    # MeetMoi
    %w(1bbdd36b-d7b0-4cdd-ac56-5e93583248a3 11fa6b53-dd3c-4f52-a130-22dc2a76e2c0 1c6c9d26-2578-4fd3-bbc5-ef432e8ca988 ff3e6ca1-5523-4b43-a5c1-0660338d7ed8 a907ad56-bf0a-4730-94d7-7906ed62712a) =>
    %w(1bbdd36b-d7b0-4cdd-ac56-5e93583248a3 11fa6b53-dd3c-4f52-a130-22dc2a76e2c0 1c6c9d26-2578-4fd3-bbc5-ef432e8ca988 ff3e6ca1-5523-4b43-a5c1-0660338d7ed8 a907ad56-bf0a-4730-94d7-7906ed62712a),
    # US interactive
    %w(d4c8ccbf-2fed-4d10-812a-155600801739 ba903446-2f43-4b8e-9650-695b344e4488 af20fb55-4500-470d-90a7-b45b864a27a0 3b235836-2fa6-44e7-addb-54c0e144c7c6 ddb1495b-6627-46e7-9052-ce0efa2c9565 f9d9e36a-5322-40c2-ba60-0c64c65309f2) =>
    %w(d4c8ccbf-2fed-4d10-812a-155600801739 ba903446-2f43-4b8e-9650-695b344e4488 af20fb55-4500-470d-90a7-b45b864a27a0 3b235836-2fa6-44e7-addb-54c0e144c7c6 ddb1495b-6627-46e7-9052-ce0efa2c9565 f9d9e36a-5322-40c2-ba60-0c64c65309f2),
    # GSN Casino
    %w(5ff6102b-42ad-4ed0-868a-cf5011f8e28c 9b861ac9-3612-4a6d-98c9-7ea8bedffff6) => %w(5ff6102b-42ad-4ed0-868a-cf5011f8e28c 9b861ac9-3612-4a6d-98c9-7ea8bedffff6),
    # Hotel Tonight Android
    %w(39e6dad0-5a6a-4bc0-8b82-10db740fbf7a 0e589ce9-0e8e-49e6-a8aa-3b992a9c9c6a) => %w(39e6dad0-5a6a-4bc0-8b82-10db740fbf7a 0e589ce9-0e8e-49e6-a8aa-3b992a9c9c6a),
    # Hotel Tonight iOS
    %w(44eac10c-57ea-4969-977f-2c60a0abb48c 71a1d3d2-20e9-4c13-a03d-ee855552271e 4d3b8250-6be5-4e59-a3af-b448d94c2f5f 6577c3b0-df65-4428-a266-49c49cc8c559 778faf7c-01c8-4756-82d7-c3718017e22f 876bbbf3-7472-4f1b-8024-81c33386640b c8196876-6458-4fab-bed6-c9306fe35b05) =>
    %w(44eac10c-57ea-4969-977f-2c60a0abb48c 71a1d3d2-20e9-4c13-a03d-ee855552271e 4d3b8250-6be5-4e59-a3af-b448d94c2f5f 6577c3b0-df65-4428-a266-49c49cc8c559 778faf7c-01c8-4756-82d7-c3718017e22f 876bbbf3-7472-4f1b-8024-81c33386640b c8196876-6458-4fab-bed6-c9306fe35b05),
    # GSN Casino Android
    %w(1e4f446b-b079-409e-af75-ec24e611a2df 77f15116-b275-4c67-9665-6b2c1d1921eb) => %w(1e4f446b-b079-409e-af75-ec24e611a2df 77f15116-b275-4c67-9665-6b2c1d1921eb),
    # 60 Second Insurance
    %w(026d1990-3e2e-4380-80c2-47e8924700e5 ea48b327-20ce-4792-91d8-47efab04eac8) => %w(026d1990-3e2e-4380-80c2-47e8924700e5 ea48b327-20ce-4792-91d8-47efab04eac8),
    # Forces of War
    %w(eb973f19-f5cc-440b-918c-1695c73e5fa2 33b20a4d-4660-4ca8-b1a7-138bb8fb1771 c7704a06-9f30-461d-b41c-d35766d491e9 f517e10a-132f-4a29-9d6b-8b2da5c2ee81 ec130850-0262-4dd6-8fd2-9f0e970bc7bf be05ed4f-945f-4dc7-b6d0-4ae033df27f7 cd7a58dc-32b0-4838-b06a-41ccf2288182) =>
    %w(eb973f19-f5cc-440b-918c-1695c73e5fa2 33b20a4d-4660-4ca8-b1a7-138bb8fb1771 c7704a06-9f30-461d-b41c-d35766d491e9 f517e10a-132f-4a29-9d6b-8b2da5c2ee81 ec130850-0262-4dd6-8fd2-9f0e970bc7bf be05ed4f-945f-4dc7-b6d0-4ae033df27f7 cd7a58dc-32b0-4838-b06a-41ccf2288182),
    # Badoo
    %w(7139ae3a-c5d1-43ed-873c-83ab440a152c 0eafb2b0-16a1-426c-90c5-ac0ef7af2abc) => %w(7139ae3a-c5d1-43ed-873c-83ab440a152c 0eafb2b0-16a1-426c-90c5-ac0ef7af2abc),
    # The Times
    %w(523bde45-1abb-487c-8cef-3e32a189034f 43adf090-10e4-4775-a006-00301e5df1eb) => %w(523bde45-1abb-487c-8cef-3e32a189034f 43adf090-10e4-4775-a006-00301e5df1eb),
    # Crickler 2 iOS
    %w(2533d812-1685-4f44-b121-a7126bd83ba8 1dd2a86d-42d0-454f-94d4-5b79a02b52cf) => %w(2533d812-1685-4f44-b121-a7126bd83ba8 1dd2a86d-42d0-454f-94d4-5b79a02b52cf),
    # CoffeeTable - Catalog Shopping for iPad
    %w(5dfbe67b-8033-4b8f-8db7-349838d7eb57 86ba87a2-c605-4fac-bb6a-e1983f9de44e c0ffa993-9ad4-48bc-9e74-a43316cc80e1 27acb266-7f9b-424d-97da-c05ea1fe58ce) =>
    %w(5dfbe67b-8033-4b8f-8db7-349838d7eb57 86ba87a2-c605-4fac-bb6a-e1983f9de44e c0ffa993-9ad4-48bc-9e74-a43316cc80e1 27acb266-7f9b-424d-97da-c05ea1fe58ce),
    # Fan Samsung on Facebook
    %w(f9c0217d-68f1-478e-83ba-39add5361738 e0fedb0d-7c87-468b-9ad6-1514c5ccb613 6182794e-6ca7-4dd5-9428-af0179af65f7 99385d2c-7009-4c1d-85f9-c62dcf44d736 9be7aeac-107a-4845-b0f6-5f037047f86b ccb5f45a-c9fc-4fc8-9024-3a5063471dc9 d44721b9-327c-4a67-81ea-6fefd2bf5f79) =>
    %w(f9c0217d-68f1-478e-83ba-39add5361738 e0fedb0d-7c87-468b-9ad6-1514c5ccb613 6182794e-6ca7-4dd5-9428-af0179af65f7 99385d2c-7009-4c1d-85f9-c62dcf44d736 9be7aeac-107a-4845-b0f6-5f037047f86b ccb5f45a-c9fc-4fc8-9024-3a5063471dc9 d44721b9-327c-4a67-81ea-6fefd2bf5f79),
    # Quickable for Craiglist eBay Android
    %w(d166d4a2-605b-4a42-8e82-26d4a5f7a482 2e320aa6-ebfc-42a5-abc9-9fb71d928ec6) => %w(d166d4a2-605b-4a42-8e82-26d4a5f7a482 2e320aa6-ebfc-42a5-abc9-9fb71d928ec6),
    # Intuit GoPayment (Android)
    %w(31e2aedc-28b8-4bf3-8bd9-37d44ff5f4b0 7da49023-1016-4f02-a2dc-c3e5ec06ec19) => %w(31e2aedc-28b8-4bf3-8bd9-37d44ff5f4b0 7da49023-1016-4f02-a2dc-c3e5ec06ec19),
    # Ebay (Generic to CPI)
    %w(6d7892ac-8d94-4cc2-ae07-7effaa9fd4ea 403ba8c9-c8aa-492d-bc5a-9f667c272a09) => %w(6d7892ac-8d94-4cc2-ae07-7effaa9fd4ea 403ba8c9-c8aa-492d-bc5a-9f667c272a09),
    # Tempur-Pedic
    %w(90df3490-e351-4a05-86d0-ddb91f28651b 76b79817-0ae0-4d01-b597-904accd142a7) => %w(90df3490-e351-4a05-86d0-ddb91f28651b 76b79817-0ae0-4d01-b597-904accd142a7),
    # Fluff Friends Rescue iOS
    %w(1165fbbf-c5c1-4fee-951f-52a8beb81d8d 7aeb04d3-9796-4ec1-90e9-f7b7e506969a bca84192-05f6-42c6-bb50-7ca3e0feb38c e973496a-1e69-4198-8c29-392bc01306ba f904bea5-05ee-4df7-b480-1767010f8cb9 18dcb8bf-7556-481b-88da-7b9d959c2d4b 49cabdd5-0f88-4d87-8483-e70c12edf760 97a839d2-2dd0-4ae4-b0db-ca72fb8d6473 6c4d9387-50a3-4dde-b6f8-6e3acda0e3e2) =>
    %w(1165fbbf-c5c1-4fee-951f-52a8beb81d8d 7aeb04d3-9796-4ec1-90e9-f7b7e506969a bca84192-05f6-42c6-bb50-7ca3e0feb38c e973496a-1e69-4198-8c29-392bc01306ba f904bea5-05ee-4df7-b480-1767010f8cb9 18dcb8bf-7556-481b-88da-7b9d959c2d4b 49cabdd5-0f88-4d87-8483-e70c12edf760 97a839d2-2dd0-4ae4-b0db-ca72fb8d6473 6c4d9387-50a3-4dde-b6f8-6e3acda0e3e2),
    # Conquer Online HD iOS
    %w(b58dcbe2-3947-4b3c-9f40-5f483c3426ba 0158a09c-0bac-4a20-b408-d37ba704f273 b28aa701-88e7-4567-9bfe-468f4a876652 497550e9-8073-41ba-a13c-ce1585d52202) =>
    %w(b58dcbe2-3947-4b3c-9f40-5f483c3426ba 0158a09c-0bac-4a20-b408-d37ba704f273 b28aa701-88e7-4567-9bfe-468f4a876652 497550e9-8073-41ba-a13c-ce1585d52202),
  }

  TAPJOY_GAMES_RETARGETED_OFFERS = ['2107dd6a-a8b7-4e31-a52b-57a1a74ddbc1', '12b7ea33-8fde-4297-bae9-b7cb444897dc', '8183ce57-8ee4-46c0-ab50-4b10862e2a27']
  TAPJOY_GAMES_OFFERS = [ TAPJOY_GAMES_REGISTRATION_OFFER_ID, LINK_FACEBOOK_WITH_TAPJOY_OFFER_ID]

  MINISCULE_REWARD_THRESHOLD = 0.25

  def postcache_rejections(publisher_app, device, currency, device_type, geoip_data, app_version,
      direct_pay_providers, type, hide_rewarded_app_installs, library_version, os_version,
      screen_layout_size, video_offer_ids, source, all_videos, mobile_carrier_code, store_whitelist, store_name)
    reject_functions = [
      { :method => :geoip_reject?, :parameters => [geoip_data], :reason => 'geoip' },
      { :method => :already_complete?, :parameters => [device, app_version], :reason => 'already_complete' },
      { :method => :prerequisites_not_complete?, :parameters => [device], :reason => 'prerequisites_not_complete' },
      { :method => :selective_opt_out_reject?, :parameters => [device], :reason => 'selective_opt_out' },
      { :method => :flixter_reject?, :parameters => [publisher_app, device], :reason => 'flixter' },
      { :method => :minimum_bid_reject?, :parameters => [currency, type], :reason => 'minimum_bid' },
      { :method => :jailbroken_reject?, :parameters => [device], :reason => 'jailbroken' },
      { :method => :direct_pay_reject?, :parameters => [direct_pay_providers], :reason => 'direct_pay' },
      { :method => :action_app_reject?, :parameters => [device], :reason => 'action_app' },
      { :method => :min_os_version_reject?, :parameters => [os_version], :reason => 'min_os_version' },
      { :method => :cookie_tracking_reject?, :parameters => [publisher_app, library_version, source], :reason => 'cookie_tracking' },
      { :method => :screen_layout_sizes_reject?, :parameters => [screen_layout_size], :reason => 'screen_layout_sizes' },
      { :method => :offer_is_the_publisher?, :parameters => [currency], :reason => 'offer_is_the_publisher' },
      { :method => :offer_is_blacklisted_by_currency?, :parameters => [currency], :reason => 'offer_is_blacklisted_by_currency' },
      { :method => :partner_is_blacklisted_by_currency?, :parameters => [currency], :reason => 'partner_is_blacklisted_by_currency' },
      { :method => :currency_only_allows_free_offers?, :parameters => [currency], :reason => 'currency_only_allows_free_offers' },
      { :method => :self_promote_reject?, :parameters => [publisher_app], :reason => 'self_promote_only' },
      { :method => :age_rating_reject?, :parameters => [ currency && currency.max_age_rating], :reason => 'age_rating' },
      { :method => :publisher_whitelist_reject?, :parameters => [publisher_app], :reason => 'publisher_whitelist' },
      { :method => :currency_whitelist_reject?, :parameters => [currency], :reason => 'currency_whitelist' },
      { :method => :frequency_capping_reject?, :parameters => [device], :reason => 'frequency_capping' },
      { :method => :tapjoy_games_retargeting_reject?, :parameters => [device], :reason => 'tapjoy_games_retargeting' },
      { :method => :source_reject?, :parameters => [source], :reason => 'source' },
      { :method => :non_rewarded_offerwall_rewarded_reject?, :parameters => [currency], :reason => 'non_rewarded_offerwall_rewarded' },
      { :method => :carriers_reject?, :parameters => [mobile_carrier_code], :reason => 'carriers' },
      { :method => :app_store_reject?, :parameters => [store_whitelist], :reason => 'app_store' },
      { :method => :distribution_reject?, :parameters => [store_name], :reason => 'distribution' },
      { :method => :miniscule_reward_reject?, :parameters => currency, :reason => 'miniscule_reward'},
      { :method => :has_coupon_already_pending?, :parameters => [device], :reason => 'coupon_already_requested'},
      { :method => :has_coupon_offer_expired?, :reason => 'coupon_expired'},
      { :method => :has_coupon_offer_not_started?, :reason => 'coupon_not_started'}
    ]
    reject_reasons(reject_functions)
  end

  def postcache_reject?(publisher_app, device, currency, device_type, geoip_data, app_version,
      direct_pay_providers, type, hide_rewarded_app_installs, library_version, os_version,
      screen_layout_size, video_offer_ids, source, all_videos, mobile_carrier_code, store_whitelist, store_name)
    geoip_reject?(geoip_data) ||
    already_complete?(device, app_version) ||
    prerequisites_not_complete?(device) ||
    selective_opt_out_reject?(device) ||
    show_rate_reject?(device, type, currency) ||
    flixter_reject?(publisher_app, device) ||
    minimum_bid_reject?(currency, type) ||
    jailbroken_reject?(device) ||
    direct_pay_reject?(direct_pay_providers) ||
    action_app_reject?(device) ||
    min_os_version_reject?(os_version) ||
    cookie_tracking_reject?(publisher_app, library_version, source) ||
    screen_layout_sizes_reject?(screen_layout_size) ||
    offer_is_the_publisher?(currency) ||
    offer_is_blacklisted_by_currency?(currency) ||
    partner_is_blacklisted_by_currency?(currency) ||
    currency_only_allows_free_offers?(currency) ||
    self_promote_reject?(publisher_app) ||
    age_rating_reject?(currency.max_age_rating) ||
    publisher_whitelist_reject?(publisher_app) ||
    currency_whitelist_reject?(currency) ||
    video_offers_reject?(video_offer_ids, type, all_videos) ||
    frequency_capping_reject?(device) ||
    tapjoy_games_retargeting_reject?(device) ||
    source_reject?(source) ||
    non_rewarded_offerwall_rewarded_reject?(currency) ||
    carriers_reject?(mobile_carrier_code) ||
    sdkless_reject?(library_version) ||
    recently_skipped?(device) ||
    has_insufficient_funds?(currency) ||
    rewarded_offerwall_non_rewarded_reject?(currency, source) ||
    app_store_reject?(store_whitelist) ||
    distribution_reject?(store_name) ||
    miniscule_reward_reject?(currency) ||
    has_coupon_already_pending?(device) ||
    has_coupon_offer_not_started? ||
    has_coupon_offer_expired?
  end

  def precache_reject?(platform_name, hide_rewarded_app_installs, normalized_device_type)
    app_platform_mismatch?(platform_name) || hide_rewarded_app_installs_reject?(hide_rewarded_app_installs) || device_platform_mismatch?(normalized_device_type)
  end

  def reject_reasons(reject_functions)
    reject_functions.select do |function_hash|
      if function_hash.keys.include?(:parameters)
        send(function_hash[:method], *function_hash[:parameters])
      else
        send(function_hash[:method])
      end
    end.map do |function_hash|
      function_hash[:reason].humanize
    end
  end

  def frequency_capping_reject?(device)
    return false unless multi_complete? && interval != Offer::FREQUENCIES_CAPPING_INTERVAL['none'] && device

    device.has_app?(item_id) && (device.last_run_time(item_id) + interval > Time.zone.now)
  end

  def recommendation_reject?(device, device_type, geoip_data, os_version)
    recommendable_types_reject? ||
      device_platform_mismatch?(device_type) ||
      geoip_reject?(geoip_data) ||
      already_complete?(device) ||
      min_os_version_reject?(os_version) ||
      age_rating_reject?(3) # reject 17+ apps
  end

  def geoip_reject?(geoip_data)
    return true if get_countries.present? && !get_countries.include?(geoip_data[:primary_country])
    return true if countries_blacklist.include?(geoip_data[:primary_country])
    return true if get_regions.present? && !get_regions.include?(geoip_data[:region])
    return true if get_dma_codes.present? && !get_dma_codes.include?(geoip_data[:dma_code])
    return true if get_cities.present? && !get_cities.include?(geoip_data[:city])
    false
  end

  def hide_rewarded_app_installs_reject?(hide_rewarded_app_installs)
    hide_rewarded_app_installs && rewarded? && Offer::REWARDED_APP_INSTALL_OFFER_TYPES.include?(item_type)
  end

  def has_insufficient_funds?(currency)
    currency.charges?(self) && partner_balance <= 0
  end

  def has_coupon_already_pending?(device)
     has_valid_coupon?(device) && device.pending_coupons.include?(self.id)
  end

  def has_coupon_offer_not_started?
    has_valid_coupon? && self.coupon.start_date > Date.today
  end

  def has_coupon_offer_expired?
    has_valid_coupon? && self.coupon.end_date <= Date.today
  end

  private

  def has_valid_coupon?(device=true)
    self.present? && device.present? && !multi_complete? && item_type == 'Coupon'
  end

  def offer_is_the_publisher?(currency)
    return false unless currency
    item_id == currency.app_id
  end

  def offer_is_blacklisted_by_currency?(currency)
    return false unless currency
    currency.get_disabled_offer_ids.include?(item_id) || currency.get_disabled_offer_ids.include?(id)
  end

  def partner_is_blacklisted_by_currency?(currency)
    return false unless currency
    currency.get_disabled_partner_ids.include?(partner_id)
  end

  def currency_only_allows_free_offers?(currency)
    return false unless currency
    currency.only_free_offers? && is_paid?
  end

  def self_promote_reject?(publisher_app)
    return false unless publisher_app
    self_promote_only? && partner_id != publisher_app.partner_id
  end

  def device_platform_mismatch?(normalized_device_type)
    return false if normalized_device_type.blank?

    !get_device_types.include?(normalized_device_type)
  end

  def app_platform_mismatch?(app_platform_name)
    return false if app_platform_name.blank?

    platform_name = get_platform
    platform_name != 'All' && platform_name != app_platform_name
  end

  def age_rating_reject?(max_age_rating)
    return false unless max_age_rating && age_rating

    max_age_rating < age_rating
  end

  def already_complete?(device, app_version = nil)
    offer_complete?(self, device, app_version)
  end

  def prerequisites_not_complete?(device)
    return false if prerequisite_offer_id.blank? && get_exclusion_prerequisite_offer_ids.blank?
    return true if prerequisite_offer_id.present? && !offer_complete?(Offer.find_in_cache(prerequisite_offer_id), device, nil, false)
    return true if get_exclusion_prerequisite_offer_ids.present? && get_exclusion_prerequisite_offer_ids.any?{ |id| offer_complete?(Offer.find_in_cache(id), device, nil, false) }
    false
  end

  def offer_complete?(offer, device, app_version = nil, skip_multi_complete = true)
    return false if offer.nil? || (skip_multi_complete && offer.multi_complete?) || device.nil?

    app_id_for_device = offer.item_id
    if offer.item_type == 'RatingOffer'
      app_id_for_device = RatingOffer.get_id_with_app_version(app_id_for_device, app_version)
    end

    ALREADY_COMPLETE_IDS.each do |target_ids, ids_to_reject|
      if target_ids.include?(app_id_for_device)
        return true if ids_to_reject.any? { |reject_id| device.has_app?(reject_id) }
      end
    end

    device.has_app?(app_id_for_device)
  end

  def recently_skipped?(device)
    device.recently_skipped?(id)
  end

  def selective_opt_out_reject?(device)
    device && device.opt_out_offer_types.include?(item_type)
  end

  def show_rate_reject?(device, type, currency)
    return false if type == Offer::VIDEO_OFFER_TYPE
    return false if NON_LIMITED_CURRENCY_IDS.include?(currency.id) && show_rate > 0
    srand( (device.key + (Time.now.to_f / 1.hour).to_i.to_s + id).hash )
    should_reject = rand > show_rate
    srand

    should_reject
  end

  def flixter_reject?(publisher_app, device)
    clash_of_titans_offer_id = '4445a5be-9244-4ce7-b65d-646ee6050208'
    tap_fish_id = '9dfa6164-9449-463f-acc4-7a7c6d7b5c81'
    tap_fish_coins_id = 'b24b873f-d949-436e-9902-7ff712f7513d'
    flixter_id = 'f8751513-67f1-4273-8e4e-73b1e685e83d'

    if id == clash_of_titans_offer_id
      # Only show offer in TapFish:
      return true unless publisher_app.id == tap_fish_id || publisher_app.id == tap_fish_coins_id

      # Only show offer if user has recently run flixter:
      return true if !device.has_app?(flixter_id) || device.last_run_time(flixter_id) < (Time.zone.now - 1.days)
    end
    false
  end

  def publisher_whitelist_reject?(publisher_app)
    publisher_app && publisher_app_whitelist.present? && !get_publisher_app_whitelist.include?(publisher_app.id)
  end

  def currency_whitelist_reject?(currency)
    currency && currency.use_whitelist? && !currency.get_offer_whitelist.include?(id)
  end

  def minimum_bid_reject?(currency, type)
    return false unless currency
    min_bid = case type
    when Offer::DEFAULT_OFFER_TYPE, Offer::VIDEO_OFFER_TYPE
      currency.minimum_offerwall_bid
    when Offer::FEATURED_OFFER_TYPE, Offer::FEATURED_BACKFILLED_OFFER_TYPE, Offer::NON_REWARDED_FEATURED_OFFER_TYPE, Offer::NON_REWARDED_FEATURED_BACKFILLED_OFFER_TYPE
      currency.minimum_featured_bid
    when Offer::DISPLAY_OFFER_TYPE, Offer::NON_REWARDED_DISPLAY_OFFER_TYPE
      currency.minimum_display_bid
    end
    min_bid.present? && bid < min_bid
  end

  def jailbroken_reject?(device)
    is_paid? && device && device.is_jailbroken?
  end

  def direct_pay_reject?(direct_pay_providers)
    direct_pay? && !direct_pay_providers.include?(direct_pay)
  end

  def action_app_reject?(device)
    item_type == "ActionOffer" && third_party_data.present? && device && !device.has_app?(third_party_data)
  end

  def min_os_version_reject?(os_version)
    return false if min_os_version.blank?
    return true if os_version.blank?

    !os_version.version_greater_than_or_equal_to?(min_os_version)
  end

  def screen_layout_sizes_reject?(screen_layout_size)
    return false if screen_layout_sizes.blank? || screen_layout_sizes == '[]'
    return true if screen_layout_size.blank?

    !get_screen_layout_sizes.include?(screen_layout_size)
  end

  def cookie_tracking_reject?(publisher_app, library_version, source)
    publisher_app && cookie_tracking? && source != 'tj_games' && publisher_app.platform == 'iphone' && !library_version.version_greater_than_or_equal_to?('8.0.3')
  end

  def video_offers_reject?(video_offer_ids, type, all_videos)
    return false if type == Offer::VIDEO_OFFER_TYPE || all_videos

    video_offer? && !video_offer_ids.include?(id)
  end

  def tapjoy_games_retargeting_reject?(device)
    has_tjm = device.present? ? device.has_app?(TAPJOY_GAMES_REGISTRATION_OFFER_ID) || device.has_app?(LINK_FACEBOOK_WITH_TAPJOY_OFFER_ID) : false
    if TAPJOY_GAMES_RETARGETED_OFFERS.include?(item_id)
      return (device && !has_tjm)
    elsif TAPJOY_GAMES_OFFERS.include?(item_id)
      return (device && has_tjm)
    end
    false
  end

  def source_reject?(source)
    get_approved_sources.any? && !get_approved_sources.include?(source)
  end

  def non_rewarded_offerwall_rewarded_reject?(currency)
    currency && !currency.rewarded? && rewarded? && item_type != 'App'
  end

  def rewarded_offerwall_non_rewarded_reject?(currency, source)
    currency && currency.rewarded? && !rewarded? && (source == 'offerwall' || source == 'tj_games')
  end

  def recommendable_types_reject?
    item_type != 'App'
  end

  def carriers_reject?(mobile_carrier_code)
    get_carriers.present? && !get_carriers.include?(Carriers::MCC_MNC_TO_CARRIER_NAME[mobile_carrier_code])
  end

  def sdkless_reject?(library_version)
    sdkless? && !library_version.to_library_version.sdkless_integration?
  end

  def app_store_reject?(store_whitelist)
    store_whitelist.present? && app_metadata_store_name && !store_whitelist.include?(app_metadata_store_name)
  end

  def distribution_reject?(store_name)
    return false unless store_name
    cached_item =  item_type.constantize.respond_to?(:find_in_cache) ? item_type.constantize.find_in_cache(item_id) : nil
    return cached_item.distribution_reject?(store_name) if cached_item.respond_to?('distribution_reject?')
    false
  end

  def miniscule_reward_reject?(currency)
    currency && currency.rewarded? && rewarded? &&
      currency.get_raw_reward_value(self) < MINISCULE_REWARD_THRESHOLD &&
      item_type != 'DeeplinkOffer'# && !rate_filter_override
  end
end
