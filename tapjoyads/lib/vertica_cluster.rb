class VerticaCluster

  def self.reset_connection
    @@nodes = Array.new(VERTICA_CONFIG['hosts'].size)
    @@offset = rand(@@nodes.size)
  end

  self.reset_connection

  def self.get_connection
    @@offset = @@offset == @@nodes.size - 1 ? 0 : @@offset + 1
    @@nodes[@@offset] ||= Vertica.connect(:host     => VERTICA_CONFIG['hosts'][@@offset],
                                          :port     => VERTICA_CONFIG['port'],
                                          :database => VERTICA_CONFIG['database'],
                                          :user     => VERTICA_CONFIG['user'],
                                          :password => VERTICA_CONFIG['password'])
  end

  def self.query(table, options = {})
    select     = options.delete(:select) { '*' }
    conditions = options.delete(:conditions)
    group      = options.delete(:group)
    order      = options.delete(:order)
    limit      = options.delete(:limit)
    raise "Unknown options #{options.keys.join(', ')}" unless options.empty?

    query  = "SELECT #{select} FROM #{table}"
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
