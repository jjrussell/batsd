node(:status) { response.status }
node(:result) do
  JSON.parse(yield)
end
