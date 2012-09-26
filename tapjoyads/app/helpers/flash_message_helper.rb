module FlashMessageHelper

  UPDATE_ERROR_MESSAGE = "Update unsuccessful."

  def update_flash_error_message(partner)
    build_flash_message(UPDATE_ERROR_MESSAGE, partner)
  end

  private

  def build_flash_message(base_message = '', partner = nil)
    if partner
      emails = partner.account_managers.map(&:email)
      email = emails.detect { |email| email.present? }
      if email
        return "#{base_message} If you have any questions, <a href=\"mailto:#{email}\">email your account manager</a>."
      end
    end
    base_message
  end

end