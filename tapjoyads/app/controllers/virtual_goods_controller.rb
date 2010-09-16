class VirtualGoodsController < WebsiteController
  layout 'tabbed'
  current_tab :apps

  filter_access_to :all

  before_filter :find_app, :only => [ :create, :new, :show, :update, :index ]
  before_filter :find_virtual_good, :only => [ :show, :update ]
  before_filter :find_all_virtual_goods, :only => :index

  def new
    @page_title = 'Create new virtual good'
    @virtual_good = VirtualGood.new unless defined? @virtual_good
    @form_action = :create
    @form_method = :post
    render :action => :show
  end

  def create
    @virtual_good = VirtualGood.new

    if update_virtual_good
      @app.cache_active_virtual_goods
      flash[:notice] = 'Sucessfully created virtual good'
      redirect_to app_virtual_good_path({ :app_id => @app.id, :id => @virtual_good.key })
    else
      new()
    end
  end

  def show
    @page_title = 'Edit virtual good'
    @form_action = :update
    @form_method = :put
  end

  def update
    if update_virtual_good
      flash[:notice] = 'Sucessfully updated virtual good'
      redirect_to app_virtual_good_path({ :app_id => @app.id, :id => @virtual_good.key })
    else
      show()
    end
  end

private

  def update_virtual_good
    @virtual_good.app_id              = @app.id
    @virtual_good.name                = params[:virtual_good][:name]
    @virtual_good.title               = params[:virtual_good][:title]
    @virtual_good.description         = params[:virtual_good][:description]
    @virtual_good.price               = params[:virtual_good][:price]
    @virtual_good.max_purchases       = params[:virtual_good][:max_purchases]
    @virtual_good.beta                = params[:virtual_good][:beta] == '1'
    @virtual_good.disabled            = params[:virtual_good][:disabled] == '1'

=begin
    if params[:virtual_good][:icon]
      bucket = S3.bucket(BucketNames::VIRTUAL_GOODS)
      bucket.put("icons/#{@virtual_good.key}.png", params[:virtual_good][:icon].read, {}, 'public-read')
      @virtual_good.has_icon = true
    end
    if params[:virtual_good][:data]
      bucket = S3.bucket(BucketNames::VIRTUAL_GOODS)
      bucket.put("data/#{@virtual_good.key}.zip", params[:virtual_good][:data].read, {}, 'public-read')
      @virtual_good.has_data = true
      @virtual_good.file_size = 0
    end
    @virtual_good.extra_attributes    = params[:virtual_good][:extra_attributes]
    @virtual_good.ordinal             = params[:virtual_good][:ordinal]
=end
    if params[:virtual_good][:name].blank?
      flash[:error] = 'Name cannot be blank'
    else
      @virtual_good.save!
      return true
    end

    return false
  end

  def find_app
    @app = current_partner.apps.find(params[:app_id])
    @virtual_good_types = @app.virtual_goods.map(&:title).uniq
  end

  def find_virtual_good
    @virtual_good = @app.find_virtual_good(params[:id])
    if @virtual_good.is_new
      flash[:error] = "Could not find virtual good with ID: #{params[:id]}"
      redirect_to apps_path
    end
  end

  def find_all_virtual_goods
    @virtual_goods = @app.virtual_goods
  end
end
