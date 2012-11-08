module Api::Client::ApiSchema
  def self.included(base)
    base.extend Api::Client::ApiSchema::ClassMethods
  end

  module ClassMethods
    def opts; @opts; end
    def api_schema(opts = {})
      opts[:only] = Array(opts[:only])
      @opts = opts
      before_filter :set_schema
    end
  end

  def set_schema
    opts = self.class.opts
    @schema = opts[:only].blank? || opts[:only].include?(params[:action].to_sym)
  end
end