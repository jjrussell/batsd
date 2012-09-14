class Alert
  attr_accessor :query, :message, :recipients_field, :fields, :recipients, :run_at_hours

  def initialize(alert, time = Time.zone.now)
    @query            = alert['query']
    @message          = alert['message']
    @fields           = alert['fields']
    @recipients_field = alert['recipients_field']
    @recipients       = alert['recipients']
    @run_at_hours     = alert['run_at_hours']
    @values_at_hours  = alert['values_at_hours']

    @time             = time

    prepare_query
  end

  def run
    if run?
      begin
        rows = vertica.query(@query).rows
      rescue Vertica::Error::QueryError
        return false
      end

      push(rows) if rows.length > 0
    end
  end

  class << self
    def run_all
      find_all.each { |alert| alert.run }
    end

    def find_all
      alerts_keys = alerts_bucket.objects.map(&:key).reject { |keys| keys.last == "/" }
      alerts_keys.map { |key| s3_alert(key) }.flatten
    end

    def s3_alert(key)
      json = alerts_bucket.objects[key].read
      begin
        JSON.parse(json).map { |alert| Alert.new(alert) }
      rescue JSON::ParserError => e
        TapjoyMailer.deliver_generic_alert(e, ['aaron@tapjoy.com', 'chris.compeau@tapjoy.com'])
      end
    end

    def alerts_bucket
      @alerts_bucket ||= S3.bucket(BucketNames::ALERTS)
    end
  end

  private

  def run?
    if @run_at_hours.blank?
      true
    else
      @run_at_hours.include?(@time.hour)
    end
  end

  def prepare_query
    if @values_at_hours && @values_at_hours.has_key?(@time.hour.to_s)
      @values_at_hours[@time.hour.to_s].each_pair do |str,sub|
        @query.gsub!(str, sub)
      end
    end
  end

  def push(rows)
    if @recipients_field
      direct_recipients = rows.collect {|row| row[@recipients_field.to_sym] }.uniq

      direct_recipients.each do |recipient|
        TapjoyMailer.deliver_alert(self, rows.select {|row| row[@recipients_field.to_sym] == recipient}, recipient)
      end
    else
      TapjoyMailer.deliver_alert(self, rows, recipients)
    end
  end

  def vertica
    @vertica ||= VerticaCluster.get_connection
  end

end
