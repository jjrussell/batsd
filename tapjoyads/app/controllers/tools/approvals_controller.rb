class Tools::ApprovalsController < WebsiteController
  layout 'tabbed'
  filter_access_to :all
  current_tab :tools
  before_filter :setup_conditions, :only => [:index, :history, :mine]
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

    redirect_to :action => :index
  end

  def reject
    @approval.owner = current_user if respond_to?(:curret_user)
    @approval.reject!(params[:reason])

    redirect_to :action => :index
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
    set_approval_type
  end

  def set_approval_type
    @conditions ||= {}
    @conditions[:item_type] = params[:type].to_s.capitalize if params[:type]
  end

end
