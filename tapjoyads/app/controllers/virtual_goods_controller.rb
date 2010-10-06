class VirtualGoodsController < WebsiteController
  include ActionView::Helpers::NumberHelper

  layout 'tabbed'
  current_tab :apps

  filter_access_to :all

  before_filter :find_app, :only => [ :create, :new, :show, :update, :index, :reorder ]
  before_filter :find_virtual_good, :only => [ :show, :update ]
  before_filter :find_all_virtual_goods, :only => :index
  before_filter :check_virtual_currency
  after_filter :save_activity_logs, :only => [ :update, :create ]

  def new
    @page_title = 'Create New Virtual Good'
    @virtual_good = VirtualGood.new unless defined? @virtual_good
    @form_action = :create
    @form_method = :post
    render :action => :show
  end

  def create
    @virtual_good = VirtualGood.new
    log_activity(@virtual_good)

    if update_virtual_good
      flash[:notice] = 'Sucessfully created virtual good'
      redirect_to app_virtual_good_path({ :app_id => @app.id, :id => @virtual_good.key })
    else
      redirect_to :back
    end
  end

  def show
    @page_title = 'Edit Virtual Good'
    @form_action = :update
    @form_method = :put
  end

  def update
    log_activity(@virtual_good)
    if update_virtual_good
      flash[:notice] = 'Sucessfully updated virtual good'
      redirect_to app_virtual_goods_path({ :app_id => @app.id })
    else
      redirect_to :back
    end
  end

  def reorder
    if params[:virtual_goods]
      keys = JSON.load(params[:virtual_goods])
      ordinal = 500
      keys.each_with_index do |key, index|
        virtual_good = VirtualGood.new(:key => key)
        if virtual_good.is_new || virtual_good.app_id != @app.id
          raise "Virtual good ordering error"
        end
        virtual_good.ordinal = ordinal + index
        virtual_good.save!
      end
    end
    redirect_to :action => 'index'
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


    if params[:virtual_good][:icon]
      icon_file = params[:virtual_good][:icon]
      if icon_file.size <= (200 << 10) # 200KB
        begin
          raise unless icon_file.read(4)[1..4] == 'PNG'
          dimensions = icon_file.read(20)[12..20].unpack('NN')
          if dimensions[0] <= 100 && dimensions[1] <= 200
            icon_file.rewind
            bucket = S3.bucket(BucketNames::VIRTUAL_GOODS)
            bucket.put("icons/#{@virtual_good.key}.png", icon_file.read, {}, 'public-read')
            @virtual_good.has_icon = true
          else
            flash[:error] = "icon file dimensions (#{dimensions.join('x')}) is too large"
            return false
          end
        rescue
          flash[:error] = "icon file may not be of PNG format"
          return false
        end
      else
        flash[:error] = "icon file size (#{number_to_human_size(icon_file.size)}) is too large"
        return false
      end
    end

    if params[:virtual_good][:data]
      if params[:virtual_good][:data].size <= (200 << 10) # 200KB
        bucket = S3.bucket(BucketNames::VIRTUAL_GOODS)
        bucket.put("data/#{@virtual_good.key}.zip", params[:virtual_good][:data].read, {}, 'public-read')
        @virtual_good.has_data = true
        @virtual_good.file_size = 0
      else
        flash[:error] = "data file size (#{number_to_human_size(params[:virtual_good][:icon].size)}) is too large"
        return false
      end
    end

    @virtual_good.extra_attributes = params[:virtual_good][:extra_attributes] if params[:virtual_good][:extra_attributes]

    if params[:virtual_good][:name].blank?
      flash[:error] = 'Name cannot be blank'
      return false
    else
      @virtual_good.save!
      return true
    end
  end

  def find_app
    @app = current_partner.apps.find_by_id(params[:app_id])
    if @app.nil?
      redirect_to apps_path
      return
    end
    @virtual_good_types = {}
    @app.virtual_goods.each do |vg|
      @virtual_good_types[vg.title] ||= vg.extra_attributes.keys
    end
  end

  def find_virtual_good
    @virtual_good = VirtualGood.new(:key => params[:id])
    if @virtual_good.is_new || @virtual_good.app_id != @app.id
      flash[:error] = "Could not find virtual good with ID: #{params[:id]}"
      redirect_to apps_path
    end
  end

  def find_all_virtual_goods
    @virtual_goods = @app.virtual_goods
  end

  def check_virtual_currency
    render 'disabled' unless @app.currency && @app.currency.tapjoy_managed?
  end
end
