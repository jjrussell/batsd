class OneOffs
  def self.download_tstore_icons
    # My choice
    app = App.find('996e6070-1cbe-4943-8369-3ecaf1c98669')
    data = {
      :item_id         => '0000288661',
      :title           => '★빅히트★마이초이스[My Choice]',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201208/21/IF1423080007520120522101330/0000288661/img/thumbnail/0000288661_180_180_0_68.PNG',
      :file_size_bytes => 25494 * 1024,
      :released_at     => Date.strptime('5/22/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.6,
      :categories      => ['게임>시뮬레이션'],
      :publisher       => '셀시티(주)',
    }
    update_icon(app, data)

    # Tiny Farm
    app = App.find('8a8f2908-66ed-4e08-a991-a3fd620800dc')
    data = {
      :item_id         => '0000264687',
      :title           => '타이니팜',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201209/04/IF142158856020090629182843/0000264687/img/thumbnail/0000264687_180_180_0_68.PNG',
      :file_size_bytes => 126012 * 1024,
      :released_at     => Date.strptime('10/31/2011', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.3,
      :categories      => ['게임>시뮬레이션'],
      :publisher       => '(주)컴투스',
    }
    update_icon(app, data)

    # Maple story
    app = App.find('1010df1b-376b-43ad-84bc-1e87c652f490')
    data = {
      :item_id         => '0000303854',
      :title           => '메이플스토리 도적편',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201209/24/IF142158931020090716174343/0000303854/img/thumbnail/0000303854_180_180_0_68.PNG',
      :file_size_bytes => 20327 * 1024,
      :released_at     => Date.strptime('9/12/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.5,
      :categories      => ['게임>시뮬레이션'],
      :publisher       => '(주)넥슨',
    }
    update_icon(app, data)

    # Elgard
    app = App.find('55007a4d-7bf8-4c5c-8db0-899e3f6eebab')
    data = {
      :item_id         => '0000298860',
      :title           => '엘가드 - 어쌔신',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201208/03/IF1423200131620101117133811/0000298860/img/thumbnail/0000298860_180_180_0_68.PNG',
      :file_size_bytes => 2113 * 1024,
      :released_at     => Date.strptime('8/1/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.8,
      :categories      => ['게임>RPG'],
      :publisher       => '(주)바이코어',
    }
    update_icon(app, data)

    # Dragon Run
    app = App.find('b8c74340-c161-43c0-ad4f-8ee014b4817a')
    data = {
      :item_id         => '0000301150',
      :title           => '[Free]드래곤런',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201209/05/IF1423000034820090903092538/0000301150/img/thumbnail/0000301150_180_180_0_68.PNG',
      :file_size_bytes => 27122 * 1024,
      :released_at     => Date.strptime('8/21/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.9,
      :categories      => ['게임>아케이드'],
      :publisher       => '(주)케이넷피',
    }
    update_icon(app, data)

    # Full Count
    app = App.find('fc9ecef7-39f0-43a4-b13e-a3ccdaa62a51')
    data = {
      :item_id         => '0000304224',
      :title           => '멀티히트 프로야구 온라인',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201209/14/IF1423200131620101117133811/0000304224/img/thumbnail/0000304224_180_180_0_68.PNG',
      :file_size_bytes => 4491 * 1024,
      :released_at     => Date.strptime('9/14/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.6,
      :categories      => ['게임>스포츠'],
      :publisher       => '(주)바이코어',
    }
    update_icon(app, data)

    # Derby Days
    app = App.find('bcb0bade-3b1c-4fe6-811f-8a6784ce50aa')
    data = {
      :item_id         => '0000277381',
      :title           => '더비데이즈',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201209/07/IF142158856020090629182843/0000277381/img/thumbnail/0000277381_180_180_0_68.PNG',
      :file_size_bytes => 40083 * 1024,
      :released_at     => Date.strptime('2/21/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.7,
      :categories      => ['게임>시뮬레이션'],
      :publisher       => '(주)컴투스',
    }
    update_icon(app, data)

    # Pro Baseball 2012
    app = App.find('7fa0b4c6-fb61-40f9-942e-927e2d67ded4')
    data = {
      :item_id         => '0000276674',
      :title           => '컴투스프로야구2012',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201209/10/IF142158856020090629182843/0000276674/img/thumbnail/0000276674_180_180_0_68.PNG',
      :file_size_bytes => 34564 * 1024,
      :released_at     => Date.strptime('2/15/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.8,
      :categories      => ['게임>스포츠'],
      :publisher       => '(주)컴투스',
    }
    update_icon(app, data)

    # Homerun Battle 2
    app = App.find('f0b9e0e6-d2d1-4e70-9169-325fbe1b9653')
    data = {
      :item_id         => '0000284274',
      :title           => '★무료★홈런배틀2',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201209/07/IF142158856020090629182843/0000284274/img/thumbnail/0000284274_180_180_0_68.PNG',
      :file_size_bytes => 54961 * 1024,
      :released_at     => Date.strptime('4/20/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.8,
      :categories      => ['게임>스포츠'],
      :publisher       => '(주)컴투스',
    }
    update_icon(app, data)

    # 9 Innings 2013
    app = App.find('16158141-2e56-4111-9573-bc1e4d8aeeec')
    data = {
      :item_id         => '0000296171',
      :title           => '★메이저리거★9이닝스:2013',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201209/10/IF142158856020090629182843/0000296171/img/thumbnail/0000296171_180_180_0_68.PNG',
      :file_size_bytes => 41554 * 1024,
      :released_at     => Date.strptime('7/11/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.8,
      :categories      => ['게임>스포츠'],
      :publisher       => '(주)컴투스',
    }
    update_icon(app, data)

    # Inotia 4
    app = App.find('a02f6702-4c20-4e59-8861-c4c154feb7f6')
    data = {
      :item_id         => '0000286102',
      :title           => '★무료★이노티아4',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201206/04/IF142158856020090629182843/0000286102/img/thumbnail/0000286102_180_180_0_68.PNG',
      :file_size_bytes => 38596 * 1024,
      :released_at     => Date.strptime('5/7/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.7,
      :categories      => ['게임>RPG'],
      :publisher       => '(주)컴투스',
    }
    update_icon(app, data)

    # Magic Tree
    app = App.find('f88805f8-b654-4dd6-8bbe-c25465d7bace')
    data = {
      :item_id         => '0000286562',
      :title           => '매직트리',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201209/07/IF142158856020090629182843/0000286562/img/thumbnail/0000286562_180_180_0_68.PNG',
      :file_size_bytes => 32287 * 1024,
      :released_at     => Date.strptime('5/11/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.8,
      :categories      => ['게임>시뮬레이션'],
      :publisher       => '(주)컴투스',
    }
    update_icon(app, data)

    # Dream Girl
    app = App.find('5fa67b61-e606-48f9-adb0-7431789c0e8a')
    data = {
      :item_id         => '0000291944',
      :title           => '★무료★드림걸',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201209/18/IF142158856020090629182843/0000291944/img/thumbnail/0000291944_180_180_0_68.PNG',
      :file_size_bytes => 44670 * 1024,
      :released_at     => Date.strptime('6/14/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.6,
      :categories      => ['게임>시뮬레이션'],
      :publisher       => '(주)컴투스',
    }
    update_icon(app, data)

    # My Movie Star
    app = App.find('4fbac60c-3129-44a4-ac0a-64a732f816a8')
    data = {
      :item_id         => '0000295777',
      :title           => '추천SNG★마이무비스타:드림하이',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201209/05/IF142158923820090714120704/0000295777/img/thumbnail/0000295777_180_180_0_68.PNG',
      :file_size_bytes => 46084 * 1024,
      :released_at     => Date.strptime('7/9/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.3,
      :categories      => ['게임>시뮬레이션'],
      :publisher       => '픽토소프트',
    }
    update_icon(app, data)

    # Killing Time
    app = App.find('07f209b5-af78-45b8-bc59-0287aa93e9b9')
    data = {
      :item_id         => '0000262180',
      :title           => '[무료]금주추천★킬링타임★',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/images/IF142255349620090806100204/0000262180/thumbnail/0000262180_180_180_0_68.PNG',
      :file_size_bytes => 21753 * 1024,
      :released_at     => Date.strptime('10/13/2011', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.7,
      :categories      => ['게임>퍼즐/보드'],
      :publisher       => '(주)피엔제이',
    }
    update_icon(app, data)

    # Slime vs Mushroom 2
    app = App.find('58e27eb4-31dc-42ad-87b4-37a141e03454')
    data = {
      :item_id         => '0000280420',
      :title           => '타이니팜',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/images/IF1423231887220110110170912/0000280420/thumbnail/0000280420_180_180_0_68.PNG',
      :file_size_bytes => 12565 * 1024,
      :released_at     => Date.strptime('3/19/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.8,
      :categories      => ['게임>액션'],
      :publisher       => 'WESTRIVER',
    }
    update_icon(app, data)

    # Retired Wizard Story
    app = App.find('8960c4c9-92d8-4ba4-a74f-7e782efb6e85')
    data = {
      :item_id         => '0000298831',
      :title           => '★매일보너스★퇴직한 마법사 이야기',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201208/02/IF1423231887220110110170912/0000298831/img/thumbnail/0000298831_180_180_0_68.PNG',
      :file_size_bytes => 9849 * 1024,
      :released_at     => Date.strptime('8/1/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.9,
      :categories      => ['게임>액션'],
      :publisher       => 'WESTRIVER',
    }
    update_icon(app, data)

    # Mushroom War
    app = App.find('42d18c65-9e58-4760-bd8b-9edfbb10864e')
    data = {
      :item_id         => '0000271322',
      :title           => '★매일보너스★버섯전쟁',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/images/IF1423231887220110110170912/0000271322/thumbnail/0000271322_180_180_0_68.PNG',
      :file_size_bytes => 15947 * 1024,
      :released_at     => Date.strptime('12/23/2011', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.1,
      :categories      => ['게임>액션'],
      :publisher       => 'WESTRIVER',
    }
    update_icon(app, data)

    # Mage Defense
    app = App.find('d4a0b116-e743-4c39-a1ca-fb2fce0a74a2')
    data = {
      :item_id         => '0000277086',
      :title           => '★매일보너스★마법사 디펜스',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/images/IF1423231887220110110170912/0000277086/thumbnail/0000277086_180_180_0_68.PNG',
      :file_size_bytes => 14442 * 1024,
      :released_at     => Date.strptime('2/20/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.4,
      :categories      => ['게임>액션'],
      :publisher       => 'WESTRIVER',
    }
    update_icon(app, data)

    # Cat War
    app = App.find('194f41eb-3bfa-4bdf-a8cc-58c98d3b0461')
    data = {
      :item_id         => '0000290678',
      :title           => '★매일보너스★고양이 전쟁',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201206/04/IF1423231887220110110170912/0000290678/img/thumbnail/0000290678_180_180_0_68.PNG',
      :file_size_bytes => 20007 * 1024,
      :released_at     => Date.strptime('6/4/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 4.9,
      :categories      => ['게임>액션'],
      :publisher       => 'WESTRIVER',
    }
    update_icon(app, data)

    # Coloroid
    app = App.find('b1c46611-2750-425f-93d1-107e89c44615')
    data = {
      :item_id         => '0000283115',
      :title           => '칼라로이드',
      :price           => 0.0,
      :description     => nil,
      :icon_url        => 'http://www.tstore.co.kr/android4/201206/11/IF1423026005720120409102233/0000283115/img/thumbnail/0000283115_180_180_0_68.PNG',
      :file_size_bytes => 83 * 1024,
      :released_at     => Date.strptime('6/11/2012', '%m/%d/%Y').strftime('%FT00:00:00Z'),
      :user_rating     => 5.0,
      :categories      => ['게임>액션'],
      :publisher       => 'Tapjoy',
    }
    update_icon(app, data)
  end

  def self.update_icon(app, data)
    app_metadata = app.app_metadatas.select {|meta| meta.store_name == 'android.SKTStore'}.first
    app_metadata.send(:download_and_save_icon!, data[:icon_url])
    app_metadata.save!

    puts "Successfully downloaded icon for metadata #{app_metadata.id}."
  rescue => e
    puts "Error downloading icon for metadata #{app_metadata.id}: #{e.message}"
    puts e.backtrace.join("\n")
  end
end
