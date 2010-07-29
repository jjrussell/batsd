##
# A Raffle Ticket is a specialized virtual good.
class RaffleTicket < VirtualGood
  self.sdb_attr :starts_at,          :type => :time
  self.sdb_attr :ends_at,            :type => :time
  self.sdb_attr :total_purchased,    :type => :int, :default_value => 0
  self.sdb_attr :prize_value,        :type => :int
  self.sdb_attr :prize_url,          :cgi_escape => true
  self.sdb_attr :winning_udid
  self.sdb_attr :winning_email,      :cgi_escape => true
  self.sdb_attr :email_status
  self.sdb_attr :distribution_status
  
  @errors = {}
  attr_accessor :errors
  
  def initialize(options = {})
    super
    put('type', 'R')
    self.price = 1
    self.max_purchases = 0
  end
  
  def self.cache_active_raffles
    active_raffles = []

    now_epoch = Time.zone.now.to_f.to_s
    RaffleTicket.select(:where => "type = 'R' and starts_at < '#{now_epoch}' and ends_at > '#{now_epoch}'") do |ticket|
      active_raffles << ticket
    end
    
    bucket = S3.bucket(BucketNames::OFFER_DATA)
    bucket.put('active_raffles', Marshal.dump(active_raffles))
    Mc.put('s3.active_raffles', active_raffles)
  end
  
  def self.get_active_raffles
    Mc.get_and_put('s3.active_raffles') do
      bucket = S3.bucket(BucketNames::OFFER_DATA)
      Marshal.restore(bucket.get('active_raffles'))
    end
  end
  
  def get_realtime_total_purchased
    self.total_purchased + Mc.get_count(self.get_total_purchased_memcached_key)
  end
  
  def get_total_purchased_memcached_key
    RaffleTicket.get_total_purchased_memcached_key(@key)
  end
  
  def self.get_total_purchased_memcached_key(key)
    "vg.total_purchased.#{key}"
  end
end