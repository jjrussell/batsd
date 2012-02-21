class Tools::ApprovalsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  before_filter :setup_conditions, :only => [:index, :history, :mine]
  before_filter :setup_partial, :only => [:index, :history, :mine]
  before_filter :find_approval, :only => [:approve, :reject, :assign]
  around_filter :json_wrapper, :only => [:approve, :reject, :assign]

  def index
    state = params[:state] =~ /^-?\d+$/ ? params[:state].to_i : Approval.enumerate_state('pending')
    @conditions[:state] = state if state > -1

    @approvals = Approval.all(:conditions => @conditions, :order => 'created_at ASC')
  end

  def history
    @conditions[:state] = Approval.enumerate_states('approved', 'rejected')

    @approvals = Approval.all(:conditions => @conditions, :order => 'created_at DESC')
    render :index
  end

  def mine
    @conditions[:owner_id] = current_user.id

    @approvals = Approval.all(:conditions => @conditions, :order => 'created_at ASC')
    render :index
  end

  def assign
    if params[:approval][:owner_id].empty?
      @approval.unassign
    else
      user = User.find(params[:approval][:owner_id])
      @approval.assign(user)
    end
  end

  def approve
    @approval.owner = current_user if respond_to?(:current_user)
    @approval.approve!
  end

  def reject
    @approval.owner = current_user if respond_to?(:current_user)
    @approval.reject!(params[:reason])
  end

  private
  def json_wrapper
    json = {:success => false}

    begin
      json[:success] = yield
    rescue ActsAsApprovable::Error => e
      json[:message] = e.message
    rescue
      json[:message] = 'An unknown error occured'
    end

    respond_to do |format|
      format.html do
        flash[:error] = json[:message] if json[:message]
        redirect_to :action => :index
      end
      format.json { render :json => json }
    end
  end

  def setup_conditions
    @conditions ||= {}

    if params[:owner_id]
      @conditions[:owner_id] = params[:owner_id]
      @conditions[:owner_id] = nil if params[:owner_id] == 0
    end
    if params[:item_type]
      @conditions[:item_type] = params[:item_type]
    end
  end

  # Check for the selected models partial, use the generic one if it doesn't exist
  def setup_partial
    @table_partial = @conditions.fetch(:item_type) { 'table' }

    if @table_partial != 'table'
      partial_path = Rails.root.join('app', 'views', 'tools', 'approvals', "_#{@table_partial}.html.#{view_language}")
      @table_partial = 'table' unless File.exist?(partial_path)
    end
  end

  def find_approval
    @approval = Approval.find(params[:id])
  end

  def view_language
    ActsAsApprovable.view_language
  end
end
