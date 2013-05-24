class FluentDataController < ApplicationController
  include AuthenticationHelper

  before_filter 'fluent_authenticate'

  def index
    return unless verify_params([:date])

    partner = Partner.find('1faa4e38-e118-4249-88f7-258d16ab24cf')
    extra_apps = [
        '91647185-9af5-4da8-80e6-6e66479837f9', '2cf8e550-2dab-432a-b5bb-87c0c7afb5f0', '856f074c-d284-449e-8d2d-f7ef85f257a7',
        '917b59ea-1d45-43e3-8a2f-9b1d1f0e142e', '192e6d0b-cc2f-44c2-957c-9481e3c223a0', '7baa7e9d-6d06-46f8-9909-162312a867de',
        'dfb4c57b-c156-4733-b53f-c99161ce4dd1', '92572adf-2cf4-4af6-a293-7715ae0508ff', 'a3f3bf6c-3e9e-4bbe-98ac-6b43d0e3814f',
        '7591b5ef-4b11-41b8-aed6-c69ecde86503', 'dae95712-0d9c-44a4-82d5-c73686726f44', 'b0388e2c-dbb5-49f6-8c90-a08d857016a4',
        '51e42b6c-5393-432d-b058-b9dd10e14a9c', '3edd25b7-0aaa-4f71-be6d-5ec621c86c74', '3e75f700-33fe-4cbd-bf1e-ac84de56605e',
        '6466e256-2a0e-4b32-b001-859398274856', '0cec66be-51c7-4180-ba06-b06991509c02', '0d62d467-d14d-4890-a2f9-a640d0ac3677',
        '33ad7add-739b-4f19-a60c-2f4a4a06012d', 'd5d4a705-c67e-4413-b219-1b3ab9692781', '1d844074-dec8-4cbb-b94f-ddbf00f7335b',
        '71a1d3d2-20e9-4c13-a03d-ee855552271e', '144462cd-09a0-4795-b5dd-3c969bedfe46', '17deab3f-8d1e-4c25-a66e-41a69113c10c',
        '3c0bae06-54d3-45bb-8c85-ad7bd9bb6210', '3368863b-0c69-4a54-8a14-2ec809140d8f', 'f09a565b-34cb-4c51-85b3-748941076d5b',
        '8535015c-1e9d-4a95-846b-d2eab56e03e1', 'e2c026ba-90db-45cc-b8a4-cdec02ea4162', 'f5313891-3ef8-4703-a2f8-1c030db21e4a',
        '9133c3cc-7d70-40c5-aee2-df638b8e1949', '432fc4e4-05c1-41ed-9a25-6f6d41451693', '5ef90a97-d626-46a0-8933-7e84495ad420',
        '919bf971-aa5c-42cd-85f5-bd043cb127e3', 'd467c51d-732d-46d0-931c-34f65fcd8281', '9268b71a-8584-4789-b944-ddbde282abfb',
        '4c817107-0636-4881-a4ab-1ad43dd76fc5', '396b1b7f-a94f-4a9c-bd70-3b45b0368ef5', '6fb00173-40ad-4d6c-ab27-77099f4c0426',
        'ce35a240-a330-446f-85f9-beb47a2c94c1', '42f5aceb-df5d-470c-bff3-1fa624d6d89a', '74b99f21-4bda-4ece-8ebe-2e22491bd046',
        '32935c20-facf-4ab9-bb72-821cbc660dbc', '92a1e0c6-880a-429a-b16f-8d65f7b1a840', '336f4f96-b3b1-4e20-a6a1-2de2d035332e',
    ]

    start_time = Time.zone.parse(params[:date])

    @date = start_time.iso8601[0,10]
    @appstats_list = []

    (partner.apps + App.find(extra_apps)).each do |app|
      appstats = Appstats.new(app.id, {
        :start_time => start_time,
        :end_time => start_time + 24.hours})

      @appstats_list << [ app, appstats ]
    end
  end
end
