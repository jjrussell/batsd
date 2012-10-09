class OneOffs
  def self.populate_tstore_apps_v2
    # Tree of abys free
    app = App.find('fff7f152-4e20-45b2-831a-d255b9d222d3')
    data = {
      :item_id         => '0000301610',
      :title           => '[FREE]트리오브어비스',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201209/26/IF1423000034820090903092538/0000301610/img/thumbnail/0000301610_180_180_0_68.PNG',
      :file_size_bytes => 23034 * 1024,
      :released_at     => Date.strptime('8/24/12', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.8,
      :categories      => ['게임>RPG'],
      :publisher       => '(주)케이넷피',
    }
    add_app(app, data)

        # Tree of abys plus
    app = App.find('5d5cade7-582c-4417-9778-4f3e3f2760bd')
    data = {
      :item_id         => '0000290423',
      :title           => '트리오브어비스',
      :price           => 4.51, #5000 wan
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201208/06/IF1423000034820090903092538/0000290423/img/thumbnail/0000290423_180_180_0_68.PNG',
      :file_size_bytes => 22899 * 1024,
      :released_at     => Date.strptime('5/31/12', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.8,
      :categories      => ['게임>RPG'],
      :publisher       => '(주)케이넷피',
    }
    add_app(app, data)

      # Chess master 2012
    app = App.find('48afb992-ef53-4776-ab5e-b7d33e4f7101')
    data = {
      :item_id         => '0000291307',
      :title           => '체스마스터2012',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201209/19/IF1423001486420090915172042/0000291307/img/thumbnail/0000291307_180_180_0_68.PNG',
      :file_size_bytes => 9545 * 1024,
      :released_at     => Date.strptime('6/11/12', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.9,
      :categories      => ['게임>퍼즐/보드'],
      :publisher       => 'mobirix',
    }
    add_app(app, data)

     # Smash Pangpang
    app = App.find('257ae800-4d7a-466e-aa17-185b8ac2e543')
    data = {
      :item_id         => '0000292228',
      :title           => '스매시팡팡SE',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201207/02/IF1423001486420090915172042/0000292228/img/thumbnail/0000292228_180_180_0_68.PNG',
      :file_size_bytes => 7122 * 1024,
      :released_at     => Date.strptime('6/15/12', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.6,
      :categories      => ['게임>스포츠'],
      :publisher       => 'mobirix',
    }
    add_app(app, data)

      # Heal the planet
    app = App.find('09cd7ad5-e00d-4c12-9f30-fa41c889ebbd')
    data = {
      :item_id         => '0000300181',
      :title           => '힐더 플래닛(Heal the Planet)',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201209/04/IF142255349620090806100204/0000300181/img/thumbnail/0000300181_180_180_0_68.PNG',
      :file_size_bytes => 24482 * 1024,
      :released_at     => Date.strptime('8/13/12', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.8,
      :categories      => ['게임>퍼즐/보드'],
      :publisher       => '(주)피엔제이',
    }
    add_app(app, data)

     # Cross Counter
    app = App.find('ff40acde-7abb-4c07-b3dc-ee9c12ddaf66')
    data = {
      :item_id         => '0000286993',
      :title           => '크로스카운터',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201206/05/IF1423471548820110919162602/0000286993/img/thumbnail/0000286993_180_180_0_68.PNG',
      :file_size_bytes => 53201 * 1024,
      :released_at     => Date.strptime('5/16/12', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.8,
      :categories      => ['게임>액션'],
      :publisher       => 'sollmo',
    }
    add_app(app, data)

      # Exitium
    app = App.find('4a3678d9-4727-40a4-a74e-a9508f48e6b2')
    data = {
      :item_id         => '0000285228',
      :title           => '무료★엑시티움★정식판풀버전',
      :price           => 0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201204/27/IF142158947620090729143638/0000285228/img/thumbnail/0000285228_180_180_0_68.PNG',
      :file_size_bytes => 70866 * 1024,
      :released_at     => Date.strptime('4/26/12', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.5,
      :categories      => ['게임>RPG'],
      :publisher       => 'minoraxis',
    }
    add_app(app, data)

     # FFAB
    app = App.find('7148e2e3-4c72-4870-9dc5-c3cb040a47b0')
    data = {
      :item_id         => '0000300371',
      :title           => '파이널 판타지 에어본 브리게이드',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201208/14/IF1423719126420120322120622/0000300371/img/thumbnail/0000300371_180_180_0_68.PNG',
      :file_size_bytes => 4138 * 1024,
      :released_at     => Date.strptime('8/14/12', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.6,
      :categories      => ['게임>RPG'],
      :publisher       => '다음 모바게(Daum Mobage)',
    }
    add_app(app, data)
  end

  def self.add_app(app, data)
    is_primary = app.app_metadatas.empty?
    app_metadata = app.add_app_metadata('android.SKTStore', data[:item_id], is_primary)
    app.name = data[:title] if is_primary
    app.save!
    app_metadata.send(:fill_app_store_data, data)
    app_metadata.send(:download_and_save_icon!, data[:icon_url])
    app_metadata.save!

    puts "Successfully added metadata #{app_metadata.id} to app #{app.id}."
  rescue => e
    puts "Error adding metadata to app #{app.id}: #{e.message}"
    puts e.backtrace.join("\n")
  end
end
