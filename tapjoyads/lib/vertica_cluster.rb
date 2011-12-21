class VerticaCluster

  def self.reset_connection
    @@nodes = Array.new(VERTICA_CONFIG['hosts'].size)
    @@offset = rand(@@nodes.size)
  end

  self.reset_connection

  def self.get_connection
    @@offset = @@offset == @@nodes.size - 1 ? 0 : @@offset + 1
    if @@nodes[@@offset].present?
      begin
        @@nodes[@@offset].query('SELECT 1')
      rescue
        @@nodes[@@offset] = nil
        Notifier.alert_new_relic(VerticaConnectionReset, "node: #{VERTICA_CONFIG['hosts'][@@offset]}")
      end
    end
    @@nodes[@@offset] ||= Vertica.connect(:host     => VERTICA_CONFIG['hosts'][@@offset],
                                          :port     => VERTICA_CONFIG['port'],
                                          :database => VERTICA_CONFIG['database'],
                                          :user     => VERTICA_CONFIG['user'],
                                          :password => VERTICA_CONFIG['password'])
  end

  def self.query(table, options = {})
    select     = options.delete(:select) { '*' }
    join       = options.delete(:join)
    conditions = options.delete(:conditions)
    group      = options.delete(:group)
    order      = options.delete(:order)
    limit      = options.delete(:limit)
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    query  = "SELECT #{select} FROM #{table}"
    query += " JOIN #{join}"        if join.present?
    query += " WHERE #{conditions}" if conditions.present?
    query += " GROUP BY #{group}"   if group.present?
    query += " ORDER BY #{order}"   if order.present?
    query += " LIMIT #{limit}"      if limit.present?

    result = get_connection.query(query)
    result.rows
  end

  def self.count(table, conditions = nil)
    query(table, { :select => "COUNT(*) AS count", :conditions => conditions }).first[:count]
  end

end
