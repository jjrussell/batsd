class OneOffs
  def self.add_update_non_html_responses_queue
    Sqs.create_queue('UpdateNonHtmlResponses', 30)
  end
end
