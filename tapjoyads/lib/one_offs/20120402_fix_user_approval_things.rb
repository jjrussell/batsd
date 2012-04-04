class OneOffs
  def self.fix_user_approval_things
    User.all(:conditions => 'state = "pending"').each do |user|
      user.update_attribute(:state, 'approved')

      email_ccs = user.current_partner.present? ? user.current_partner.account_managers.map(&:email) : nil
      ApprovalMailer.deliver_approved(user.email, :user, :subject => 'Your account has been accepted at Tapjoy!', :cc => email_ccs)
    end
  end
end
