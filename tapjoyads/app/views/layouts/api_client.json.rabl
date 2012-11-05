object false
extends (params[:controller] + "/" + params[:action] + '_schema') if @schema
extends 'api/client/common/pagination' if @pagination_info
node(:status) { response.status }
node(:result) do
  JSON.parse(yield)
end
