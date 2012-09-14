class Job::QueueTerminateNodesController < Job::SqsReaderController

  def initialize
    super QueueNames::TERMINATE_NODES
  end

  private

  def on_message(message)
    # .first.each is goofy, but it's due to the way chef searches return
    Chef::Search::Query.new.search(:node, "ec2_instance_id:#{instance_id(message.body)}").first.each do |node|
      begin
        Chef::ApiClient.load(node.name).destroy
      rescue Net::HTTPServerException
        # client not found
      end
      begin
        node.destroy
      rescue Net::HTTPServerException
        # node not found... weird, but don't want to fail anyway
        Airbrake.notify_or_ignore(
                                    :error_class => 'Chef::NodeDeleteFailed',
                                    :error_message => "Couldn't delete node #{node.name}",
                                    :params => {:node_name => node.name, :instance_id => instance_id(message.body)}
                                  )
      end
    end
  end

  def instance_id(body)
    begin
      JSON.parse(JSON.parse(body)["Message"])["EC2InstanceId"]
    rescue JSON::ParserError
      JSON.parse(body)["Message"]["EC2InstanceId"]
    end
  end

end
