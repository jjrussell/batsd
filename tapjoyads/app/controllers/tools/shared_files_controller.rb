class Tools::SharedFilesController < WebsiteController
  layout 'tabbed'

  current_tab :tools
  filter_access_to :all

  before_filter :setup

  def index
    @objects = @bucket.objects.with_prefix(current_user.id)
  end

  def create
    if params[:file_name].present? && params[:file_content].present?
      object = @bucket.objects["#{current_user.id}/#{params[:file_name]}"]
      if object.exists?
        flash[:error] = 'File already exists!'
      else
        object.write(:data => params[:file_content].read, :acl => :public_read)
        flash[:notice] = 'File uploaded successfully.'
      end
    else
      flash[:error] = 'You must enter a file name and choose a file to upload!'
    end
    redirect_to :action => :index
  end

  def delete
    object = @bucket.objects["#{current_user.id}/#{params[:file_name]}"]
    object.delete if object.exists?
    flash[:notice] = 'File deleted successfully.'
    redirect_to :action => :index
  end

  private

  def setup
    @bucket = S3.bucket(BucketNames::TAPJOY_DOCS)
  end

end
