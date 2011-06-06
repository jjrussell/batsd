class OneOffs

  def self.copy_ranks_to_s3(start_time_string=nil, end_time_string=nil, granularity_string='hourly')
    start_time, end_time, granularity = Appstats.parse_dates(start_time_string, end_time_string, granularity_string)
    if granularity_string == 'daily'
      date_format = ('%Y-%m')
      incrementer = 1.month
    else
      date_format = ('%Y-%m-%d')
      incrementer = 1.day
    end

    time = start_time
    while time < end_time
      copy_ranks(time.strftime(date_format))
      time += incrementer
    end
  end

  def self.copy_ranks(date_string)
    Stats.select(:where => "itemName() like 'app.#{date_string}.%'") do |stats|
      puts stats.key
      ranks_key = stats.key.gsub('app', 'ranks').gsub('.', '/')
      ranks = {}
      stats.parsed_ranks.each do |key, value|
        ranks[key] = value
      end
      unless ranks.empty?
        s3_ranks = S3Stats::Ranks.find_or_initialize_by_id(ranks_key)
        s3_ranks.all_ranks = ranks
        s3_ranks.save!
      end
    end
  end

  def self.delete_ranks_from_sdb(start_time_string=nil, end_time_string=nil, granularity_string='hourly')
    start_time, end_time, granularity = Appstats.parse_dates(start_time_string, end_time_string, granularity_string)
    if granularity == :daily
      date_format = ('%Y-%m')
      incrementer = 1.month
    else
      date_format = ('%Y-%m-%d')
      incrementer = 1.day
    end

    time = start_time
    while time < end_time
      delete_ranks(time.strftime(date_format))
      time += incrementer
    end
  end

  def self.delete_ranks(date_string)
    Stats.select(:where => "itemName() like 'app.#{date_string}.%'") do |stats|
      stats.delete('ranks')
      stats.serial_save
    end
  end
  
  def self.queue_udid_reports
    start_time = Time.zone.parse('2010-10-01')
    end_time = Time.zone.parse('2011-06-01')
    Offer.find_each do |offer|
      next if offer.id == '2349536b-c810-47d7-836c-2cd47cd3a796' # tested with this offer so they are already complete
      puts offer.id
      s = Appstats.new(offer.id, {:start_time => start_time, :end_time => end_time, :granularity => :daily, :stat_types => ['paid_installs']})
      s.stats['paid_installs'].each_with_index do |num_installs, idx|
        if num_installs > 0
          message = {:offer_id => offer.id, :date => (start_time + idx.days).strftime('%Y-%m-%d')}.to_json
          Sqs.send_message(QueueNames::UDID_REPORTS, message)
        end
      end
    end
  end

  def self.assign_admin_devices

    user_devices = {
      'amir' => [
        '3f7358a8-69f3-4d31-8c97-21825f079a7a',
        '624237d2-f0a1-4b2e-906e-963eb9c95f12',
        '7c6a56e2-5589-4be4-9efb-eac619a623e5',
        '8d13bf1b-a021-46fe-a18f-bd1b25d19729',
      ],
      'aveline' => [
        'f4378294-1fa6-4833-8476-362cb3cc532d',
        '70d1abab-005c-4c27-8e56-d56da67594d1',
        'aba2215c-d24a-4c37-b61c-f2485a726b10',
      ],
      'brian.kealer' => [
        '23e7916b-a663-4574-9f73-f702762c383a',
        '334ae826-7000-44b1-9f35-73e413bd3d1e',
      ],
      'brian.roth' => [
        '151cf228-751c-489a-a2e1-b07c9432d5a4',
      ],
      'brian.sapp' => [
        'c2e5c545-b865-48a2-994d-c30c72eea8e5',
        '8e4cbd23-4dde-4761-8a3c-37a292ce7a50',
      ],
      'ca' => [
        '7230c2a6-c8ed-48e6-9209-ef9033206eee',
      ],
      'christine' => [
        'eae0b39f-222c-46b8-8267-afe739b03b3a',
        '52a5ddfd-3cba-44a2-b900-afe291204e04',
      ],
      'daniel.lim' => [
        '6d15cd33-bb99-4185-8b1b-bd21248b7ae0',
        'd1e70561-c215-42e8-80cb-72dfeca53868',
        '10e7061d-edf2-40eb-9cce-d33cc363e4e7',
      ],
      'hwanjoon' => [
        'd8298a3e-afa1-4957-acd2-7ffc8468d807',
        'a637bffe-9b2b-46a5-b6ec-ab2e334f28e6',
        'b81e4590-64c0-4eba-bea0-2e3fc158746b',
        '26679e8f-f0e9-4168-847b-5e0f2abc60e4',
        '77912bf6-151a-4fcb-9f38-0ede2af3b508',
      ],
      'johnny' => [
        'ab53311b-3c11-44bc-933f-37e6e692374f',
        'd1adb7e6-da78-46f0-951b-457eee4b9c39',
      ],
      'dengkai' => [
        'a364e317-b5f5-4d3d-ad7f-7068b3c6cc37',
        '687b7b5b-a5a7-4d88-963f-3df297d97a72',
      ],
      'katherine.zhang' => [
        '485a5ddb-cc18-4b13-97c7-39edb4b54b44',
        '28ed167d-39c0-4333-ba7a-0e40d1fe7d83',
      ],
      'kris' => [
        '5502ff70-0b2d-4e76-92cd-945adf3b746d',
        '329e38a2-bfc9-4b94-9876-434bac4b3df1',
      ],
      'laura' => [
        'bf1fda12-5938-4c95-885f-435c7cb0bc54',
      ],
      'linda' => [
        'c10d74bc-890c-48c7-8f98-9764c13099c3',
        'dafbe36c-c6c4-4ef0-86fc-6fead8cd94ea',
        'ffd84236-237e-4654-bea1-69a2080a6e15',
        '0265315e-896c-488d-a630-e6f9bd6e9269',
        '8f1cc3b5-a061-4b36-996d-59641ac516c1',
        '67f0b63b-b4c6-42ee-8485-b1d3dd10ba69',
      ],
      'marc.bourget' => [
        'a9ce5ce9-dee5-4fc4-8566-701a6d0d0305',
      ],
      'mary.bloom' => [
        '381ef581-1a4e-47cc-83fc-0c18eb2fb859',
      ],
      'matt.kaye' => [
        '31988068-7cc3-4041-a087-fc46f4832868',
        '803ee182-6b36-4d91-afec-e489526d5ee2',
      ],
      'nick.garnes' => [
        'dfb48ad2-92a3-42fc-96ee-a175c571798e',
        'c289ae84-d7d8-41e6-942a-98d08619f25c',
      ],
      'norman.chan' => [
        'e55364c0-b5fc-40e1-9b03-d937963ebb13',
      ],
      'rob.carroll' => [
        '1f153df9-0104-43c8-893b-6fd9806573a1',
        '7d5f2dea-84da-46ce-bd3c-02c165bd345c',
      ],
      'ryan' => [
        '699b2820-bdbe-476a-9de8-0b646bf142b6',
        '7ed68bc5-02af-4afe-af9c-9f8479d0e6fc',
        '912b0af1-ba6a-4034-a27d-2e788f3a6db8',
      ],
      'sarah.chafer' => [
        'e7a1ef2e-c46f-4680-88d0-1aedd6869d5e',
      ],
      'stephen' => [
        '0644b9f8-8aed-48a5-9222-afd34dabc70a',
        '41a50e5c-1e66-4cc5-8492-7de10270ef69',
        '32c5630b-923c-4771-ad05-e098f9609a6f',
      ],
      'steve' => [
        '2cdc7e76-27cc-4b7c-b3a1-78e8c539456b',
      ],
      'sunny.cha' => [
        '99559acb-361e-42f7-b3ad-20f2ae1293b6',
      ],
      'Tehyon.kim' => [
        '4e0aeace-7def-430e-b160-cdea1fe19398',
      ],
      'tammy.taw' => [
        '183088c0-02cd-4ad3-8d7e-e9d138fbc006',
        '20404b10-99bf-4813-bb14-6cc7fdc27cda',
      ],
      'tom' => [
        '40cefb82-d472-4f89-be87-24e10d09af3f',
      ],
    }
    user_devices.each do |login, device_ids|
      user = User.find_by_email("#{login}@tapjoy.com")
      device_ids.each do |device_id|
        device = AdminDevice.find_by_id(device_id)
        unless device.nil?
          device.user = user
          device.save
        end
      end
    end
  end
end
