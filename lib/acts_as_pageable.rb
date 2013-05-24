
# In order to use this, you must have a pagable resource. 
# An including class needs to set a scope that specifies the scope of the resource
class PageableActionRequiredException < Exception; end

module ActsAsPageable

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    DEFAULT_PAGE           = 1
    DEFAULT_PAGE_SIZE      = 30
    DEFAULT_PAGING_OPTIONS = {
      :current_page => DEFAULT_PAGE,
      :per_page     => DEFAULT_PAGE_SIZE
    }

    def collection; @collection; end
    def paging_options; @paging_options; end

    def pageable_resource(prop, options = {})
      @collection            = prop.to_sym
      @paging_options        = DEFAULT_PAGING_OPTIONS.merge(options)
      @paging_options[:only] = Array(options[:only])
      if @paging_options[:only].empty?
        raise PageableActionRequiredException.new('Please specify pageable controller actions using the :only option')
      end

      #Set the results in the controller
      self.send :before_filter, :page_results
      @collection
    end

    def valid_action?(a)
      paging_options[:only].include?(a.to_sym)
    end

    def invalid_action?(a)
      !valid_action?(a)
    end
  end

  def resource
    instance_variable_get("@#{self.class.collection}")
  end

  def resource=(val)
    instance_variable_set("@#{self.class.collection}",val)
  end

  def pagination_info; @pagination_info; end

  def page_number
    params[:page] || self.class.paging_options[:start_page]
  end

  def per_page
    params[:per_page] || self.class.paging_options[:per_page]
  end

  def page_results
    return if self.class.invalid_action?(params[:action])
    run_query!
    set_pagination_info!
  end

  def run_query!
    self.resource = self.resource.paginate(:page => page_number, :per_page => per_page).all unless self.resource.nil?
  end

  def set_pagination_info!
    @pagination_info = {
      :count_items  => resource.total_entries,
      :count_pages  => (resource.total_entries.to_f / resource.per_page).ceil,
      :current_page => resource.current_page,
      :per_page     => resource.per_page
    } unless resource.nil?
  end
end
