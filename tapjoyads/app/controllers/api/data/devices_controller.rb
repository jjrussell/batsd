class Api::Data::DevicesController < ApiController

  def show
    device = Device.find(params[:id])
    render_json_error(['Unable to find the device']) and return unless device

    render :json => simpledb_object_to_json(device)
  end
end
