class OneOffs
  def self.fix_currencies
    count = 0

    Currency.all.each do |currency|
      log_activity_and_save!(currency, 'fix_currencies') do
        if currency.test_devices[/,/]
          currency.test_devices = currency.test_devices.gsub(/,/, ';')
        end
        if currency.has_invalid_test_devices?
          if currency.test_devices.length % 40 == 0
            currency.test_devices = currency.test_devices.scan(/.{1,20}/).join(';')
          end
        end
        if currency.changed?
          puts currency.test_devices
          count += 1
        end
      end
    end

    puts "#{count} currencies fixed"
  end
end
