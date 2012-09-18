class AdminDeviceLastRun < SimpledbResource
  self.domain_name = 'admin_device_last_run'

  self.sdb_attr :tapjoy_device_id
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
    opts[:tapjoy_device_id] = opts[:udid] if !opts.has_key?(:tapjoy_device_id) && opts[:udid].present?
    opts.slice!(:tapjoy_device_id, :app_id)
    raise ArgumentError if opts.empty?

    if opts[:tapjoy_device_id].present? && opts[:app_id].present?
      where = %{(tapjoy_device_id = "#{opts[:tapjoy_device_id]}" or udid = "#{opts[:tapjoy_device_id]}") and app_id = "#{opts[:app_id]}"}
    elsif opts[:tapjoy_device_id].present? && opts[:app_id].blank?
      where = %{(tapjoy_device_id = "#{opts[:tapjoy_device_id]}" or udid = "#{opts[:tapjoy_device_id]}")}
    else
      where = %{app_id = "#{opts[:app_id]}"}
    end

    select_options = {
      :where    => where + " and time is not null",
      :order_by => 'time DESC',
      :limit => limit
    }

    self.select(select_options)[:items]
  end

  def tapjoy_device_id
    get('tapjoy_device_id') || udid
  end

  def tapjoy_device_id=(tj_id)
    put('tapjoy_device_id', tj_id)
  end

  # set the last run for a [:udid, :app_id] tuple (to now)
  # and store data with the associated web request
  def self.add(opts = {})
    opts[:tapjoy_device_id] = opts[:udid] if !opts.has_key?(:tapjoy_device_id) && opts[:udid].present?
    raise ArgumentError unless [:tapjoy_device_id, :app_id].all? { |key| opts[key].present? }
    raise ArgumentError unless opts[:web_request].is_a?(WebRequest)

    last_run = self.new
    last_run.tapjoy_device_id = opts[:tapjoy_device_id]
    last_run.udid             = opts[:udid]
    last_run.app_id           = opts[:app_id]
    last_run.time             = Time.zone.now

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
