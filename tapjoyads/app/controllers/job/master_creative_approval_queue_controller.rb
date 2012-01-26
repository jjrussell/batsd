class Job::MasterCreativeApprovalQueueController < Job::JobController
  def stale
    queued = {}

    # Collapse into a hash and send mails after, to prevent a blast of (practically) duplicate emails
    CreativeApprovalQueue.stale.each do |queue|
      queued[queue.offer] ||= []
      queued[queue.offer] << queue.size
    end

    queued.each do |offer, sizes|
      approval_link = creative_tools_offers_url(:offer_id => offer.id)
      emails = offer.partner.account_managers.map(&:email)
      emails << 'support@tapjoy.com'
      emails.each do |mgr|
        TapjoyMailer.deliver_approve_stale_offer_creative(mgr, offer, sizes, approval_link)
      end
    end

    render :text => 'OK'
  end
end
