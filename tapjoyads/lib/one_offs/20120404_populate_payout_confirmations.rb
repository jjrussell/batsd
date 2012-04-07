class OneOffs
  def self.populate_payout_confirmations
      payout_confirmations = []
      Partner.find_each do |partner|

        payout_threshold_confirmation = partner.confirmed_for_payout || partner.payout_confirmation_notes.nil? || !partner.payout_confirmation_notes =~ /^SYSTEM:.*threshold.*$/
        payout_info_confirmation = partner.confirmed_for_payout || !partner.payout_confirmation_notes.nil? || !partner.payout_confirmation_notes =~ /^SYSTEM:.*changed.*$/

        date_time = Time.now.to_s(:db)

        payout_confirmations << "('#{UUIDTools::UUID.random_create.to_s }','#{partner.id}', '#{PayoutInfoConfirmation.name}', #{payout_info_confirmation ? 1 : 0}, '#{date_time}','#{date_time}' )"
        payout_confirmations << "('#{UUIDTools::UUID.random_create.to_s }', '#{partner.id}', '#{PayoutThresholdConfirmation.name}', #{payout_threshold_confirmation ? 1 : 0}, '#{date_time}', '#{date_time}')"
        if payout_confirmations.size >= 10000
          PayoutConfirmation.connection.execute("INSERT INTO PAYOUT_CONFIRMATIONS (`id`, `partner_id`, `type`, `confirmed`, `created_at`, `updated_at`) VALUES #{payout_confirmations.join(', ')} ")
          payout_confirmations = []
        end
      end
      PayoutConfirmation.connection.execute("INSERT INTO PAYOUT_CONFIRMATIONS (`id`, `partner_id`, `type`, `confirmed`, `created_at`, `updated_at`) VALUES #{payout_confirmations.join(', ')} ") unless payout_confirmations.empty?
  end
end
