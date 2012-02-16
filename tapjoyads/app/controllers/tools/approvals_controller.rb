class Tools::ApprovalsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  before_filter :setup_conditions, :only => [:index, :history, :mine]
  before_filter :setup_partial, :only => [:index, :history, :mine]
  before_filter :find_approval, :only => [:approve, :reject, :assign]

  def index
    state = params[:state] || Approval.enumerate_state('pending')
    @conditions[:state] = state if state > -1

    @approvals = Approval.all(:conditions => @conditions, :order => 'created_at ASC')
  end

  def history
    @conditions[:state] = Approval.enumerate_state('approved', 'rejected')

    @approvals = Approval.all(:conditions => @conditions, :order => 'created_at DESC')
    render :index
  end

  def mine
    @conditions[:owner_id] = current_user.id

    @approvals = Approval.all(:conditions => @conditions, :order => 'created_at ASC')
    render :index
  end

  def assign
    json = json_wrapper do
      if params[:approval][:owner_id].empty?
        @approval.unassign
      else
        user = User.find(params[:approval][:owner_id])
        if success = @approval.assign(user)
          ApprovalMailer.deliver_assigned(user.email, @approval.item_type, mine_tools_approvals_url)
        end
      end
    end

    render :json => json
  end

  def approve
    json = json_wrapper do
      @approval.owner = current_user if respond_to?(:curret_user)
      @approval.approve!
    end

    render :json => json
  end

  def reject
    json = json_wrapper do
      @approval.owner = current_user if respond_to?(:curret_user)
      @approval.reject!(params[:reason])
    end

    render :json => json
  end

  private
  def json_wrapper
    json = {:success => false}

    begin
      json[:success] = yield
    rescue ActsAsApprovable::Error => e
      json[:message] = e.message
    end

    json
  end

  def setup_conditions
    @conditions ||= {}

    if params[:owner_id].present?
      @conditions[:owner_id] = params[:owner_id]
      @conditions[:owner_id] = nil if params[:owner_id] == 0
    end
    if params[:item_type].present?
      @conditions[:item_type] = params[:item_type]
    end
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

=begin
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
=end

  # Check for the selected models partial, use the generic one if it doesn't exist
  def setup_partial
    @table_partial = @conditions.fetch(:item_type) { 'table' }.downcase
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
