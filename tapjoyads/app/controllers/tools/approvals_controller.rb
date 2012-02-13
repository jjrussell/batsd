class Tools::ApprovalsController < WebsiteController
  layout 'tabbed'
  filter_access_to :all
  current_tab :tools
  before_filter :setup_conditions, :only => [:index, :history, :mine]
  before_filter :setup_partial, :only => [:index, :history, :mine]
  before_filter :find_approval, :only => [:approve, :reject, :assign]

  def index
    state = (params[:approval] && params[:approval][:state]) || 'pending'
    @conditions[:state] = state if state != 'any'

    @approvals = Approval.all(:conditions => @conditions)
  end

  def history
    @conditions[:state] = ['approved', 'rejected']

    @approvals = Approval.all(:conditions => @conditions)
    render :index
  end

  def approve
    @approval.owner = current_user if respond_to?(:curret_user)
    i = @approval.item
    i.approve!
    @approval.approve!

    redirect_to :action => :index, :type => params[:type]
  end

  def reject
    @approval.owner = current_user if respond_to?(:curret_user)
    @approval.reject!(params[:reason])

    redirect_to :action => :index, :type => params[:type]
  end

  private
  def setup_conditions
    @conditions ||= {}
    @conditions[:item_type] = params[:type].to_s.capitalize if params[:type]
    if params[:approval]
      if params[:approval][:owner_id].present?
        @conditions[:owner_id] = params[:approval][:owner_id]
        @conditions[:owner_id] = nil if params[:approval][:owner_id] == 0
      end

      if params[:approval][:item_type].present?
        @conditions[:item_type] = params[:approval][:item_type]
      end
    end
  end

  def find_approval
    @approval = Approval.find(params[:id])
  end

    # Check for the selected models partial, use the generic one if it doesn't exist
  def setup_partial
    @table_partial = @conditions.fetch(:item_type) { 'table' }.tableize.singularize

    if @table_partial != 'table'
      partial_path = Rails.root.join('app', 'views', 'tools', 'approvals', "_#{@table_partial}.html.#{view_language}")
      @table_partial = 'table' unless File.exist?(partial_path)
    end
  end

  def view_language
    ActsAsApprovable.view_language
  end

end
