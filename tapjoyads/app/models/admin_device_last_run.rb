class AdminDeviceLastRun < SimpledbResource
  self.domain_name = 'admin_device_last_run'

  self.sdb_attr :udid
  self.sdb_attr :app_id
  self.sdb_attr :time, :type => :time

  # since SDB lets us have rows with varying keys,
  # we will use whatever parameters WebRequest
  # currently knows about (~90 params)
  WebRequest.attributes.each do |key, type|
    self.sdb_attr(key, :type => type)
  end

  # opts.keys == [:udid, :app_id] => last time this admin device ran this app
  # opts.keys == [:udid] => last time this admin device ran any app
  # opts.keys == [:app_id] => last time any admin device ran this app
  def self.for(opts = {})
    limit = opts[:limit] || 20
    opts.slice!(:udid, :app_id)
    raise ArgumentError if opts.empty?

    select_options = {
      :where    => opts.collect { |k, v| %{#{k} = "#{v}"} }.join(' and ') + " and time is not null",
      :order_by => 'time DESC',
      :limit => limit
    }

    self.select(select_options)[:items]
  end

  # set the last run for a [:udid, :app_id] tuple (to now)
  # and store data with the associated web request
  def self.add(opts = {})
    raise ArgumentError unless [:udid, :app_id].all? { |key| opts[key].present? }
    raise ArgumentError unless opts[:web_request].is_a?(WebRequest)

    last_run = self.new
    last_run.udid   = opts[:udid]
    last_run.app_id = opts[:app_id]
    last_run.time   = Time.zone.now

    # We mp-snagged these parameters from WebRequest,
    # so we have to mp-assign them
    opts[:web_request].attributes.keys.each do |key|
      assign_method = :"#{key}="
      last_run.send(assign_method, opts[:web_request].send(key)) if last_run.respond_to?(assign_method)
    end

    last_run.save
    last_run
  end
end
