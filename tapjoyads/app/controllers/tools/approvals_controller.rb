class Tools::ApprovalsController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  before_filter :setup_conditions, :only => [:index, :history, :mine]
  before_filter :setup_partial, :only => [:index, :history, :mine]
  before_filter :find_approval, :only => [:approve, :reject, :assign]

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
    @hide_owner = true

    @approvals = Approval.all(:conditions => @conditions, :order => 'created_at ASC')
    render :index
  end

  def assign
    json_wrapper do
      if params[:approval][:owner_id].empty?
        @approval.unassign
      else
        user = User.find(params[:approval][:owner_id])
        if @approval.assign(user)
          ApprovalMailer.deliver_assigned(user.email, @approval.item_type, :url => mine_tools_approvals_url)
        end
      end
    end
  end

  def approve
    json_wrapper do
      @approval.owner = current_user if respond_to?(:current_user)
      @approval.approve!
    end
  end

  def reject
    json_wrapper do
      @approval.owner = current_user if respond_to?(:current_user)
      @approval.reject!(params[:reason])
    end
  end

  private
  def json_wrapper
    json = {:success => false}

    begin
      json[:success] = yield
    rescue ActsAsApprovable::Error => e
      json[:message] = e.message
    rescue => e
      ::Rails.logger.debug e.message
      ::Rails.logger.debug e.backtrace.join("\n")
      json[:message] = 'An unknown error occured'
    end

    render :json => json
  end

  def setup_conditions
    @conditions ||= {}

    @conditions[:owner_id] = params[:owner_id] if params[:owner_id].present?
    @conditions[:item_type] = params[:type].to_s.capitalize if params[:type].present?
    @conditions[:item_type] ||= params[:item_type] if params[:item_type].present?

    @hide_type = params[:type].present?
  end

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
