class AppleEPF
  TAPJOY_EPF_CREDENTIALS = [ENV['TAPJOY_EPF_USERNAME'],ENV['TAPJOY_EPF_KEY']]
  APPLE_EPF_BASE_URL = 'http://feeds.itunes.apple.com/feeds/epf/v3/'
  EPF_FILES = ['itunes#/application', 'itunes#/application_detail', 'itunes#/genre', 'itunes#/genre_application', 'itunes#/storefront', 'popularity#/application_popularity_per_genre' ]
  S3_EPF_BASE = 'epf/'

  def self.process_full
    begin
      full_current = Nokogiri::HTML(open("#{APPLE_EPF_BASE_URL}full/current/", :http_basic_authentication => TAPJOY_EPF_CREDENTIALS))
      full_current_files = extract_files_from_apache_directory_listing(full_current)
      full_date = date_from_file(full_current_files.first)
      Set.new(EPF_FILES.collect{|file| file.slice(/^.*#/).sub('#', full_date)}).each do |archive|
        download_and_extract("#{APPLE_EPF_BASE_URL}full/current/#{archive}.tbz", generate_file_urls(full_date), true, true)
        upload_files_in_tmp_folder
      end
      S3.bucket(BucketNames::APPLE_EPF).objects[S3_EPF_BASE + 'full_date'].write(:data => full_date, :acl => :public_read)
    ensure
      FileUtils.rm_rf('tmp/epf')
    end
  end

  def self.process_incremental
    begin
      inc_current = Nokogiri::HTML(open("#{APPLE_EPF_BASE_URL}full/current/incremental/current/", :http_basic_authentication => TAPJOY_EPF_CREDENTIALS))
      inc_current_files = extract_files_from_apache_directory_listing(inc_current)
      inc_date = date_from_file(inc_current_files.first)
      Set.new(EPF_FILES.collect{|file| file.slice(/^.*#/).sub('#', inc_date)}).each do |archive|
        download_and_extract("#{APPLE_EPF_BASE_URL}full/current/incremental/current/#{archive}.tbz", generate_file_urls(inc_date), true, false)
        upload_files_in_tmp_folder
      end
      S3.bucket(BucketNames::APPLE_EPF).objects[S3_EPF_BASE + 'incremental_date'].write(:data => inc_date, :acl => :public_read)
    ensure
      FileUtils.rm_rf('tmp/epf')
    end
  end

  def self.extract_files_from_apache_directory_listing(html_data)
    files_list = []
    html_data.css('table tr td a').each do |row|
      files_list << row.values.to_s if row.values.to_s =~ /.*\.tbz$/
    end
    files_list
  end

  def self.date_from_file(file_name)
    file_name.slice(file_name =~ /[0-9]/, 8)
  end

  def self.download_file(url, credentials = true)
    file = Tempfile.new("#{url.split('/').last}")
    uri = URI(url)
    Net::HTTP.start(uri.host) do |http|
      request = Net::HTTP::Get.new uri.request_uri
      request.basic_auth *TAPJOY_EPF_CREDENTIALS if credentials
      http.request request do |response|
        response.read_body do |chunk|
          file.write(chunk)
        end
      end
    end
    file.rewind
    file
  end

  def self.extract_from_archive(archive, list_of_files, full = false)
    reader = Bzip2::Reader.new(archive)
    #Minitar's unpack requires the object to respond to pos and rewind, but faking them don't seem to prevent it from working.
    reader.instance_eval do
      def pos
        0
      end
      def rewind
        nil
      end
    end
    begin
      Archive::Tar::Minitar.unpack(reader, "tmp/epf/#{full ? 'full' : 'incremental'}", list_of_files)
    rescue => e
      Rails.logger.error e.backtrace
    end
    list_of_files
  end

  def self.download_and_extract(url, list_of_files, credentials = true, full = false)
    begin
      file = download_file(url, credentials)
      extract_from_archive(file, list_of_files, full)
      list_of_files
    ensure
      file.close! if file
    end
  end

  def self.generate_file_urls(date)
    EPF_FILES.map! do |name|
      name.sub '#', date
    end
  end

  def self.upload_files_in_tmp_folder
    Dir.glob('tmp/epf/**/*').each do |file_name|
      next if File.directory? file_name
      S3.bucket(BucketNames::APPLE_EPF).objects[S3_EPF_BASE + file_name.sub('tmp/epf/', '')].write(:data => open(file_name), :acl => :public_read)
      File.delete(file_name)
    end
    FileUtils.rm_rf('tmp/epf')
  end

  def self.test
    download_and_extract('http://s3.amazonaws.com/dev_apple-epf/test/match20120920.tbz', ['match20120920/artist_match'], false, false)
    upload_files_in_tmp_folder
  end

end
