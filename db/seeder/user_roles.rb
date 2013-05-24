class Seeder::UserRoles < Seeder
# +------------+--------------+------+-----+---------+-------+
# | Field      | Type         | Null | Key | Default | Extra |
# +------------+--------------+------+-----+---------+-------+
# | id         | char(36)     | NO   | PRI | NULL    |       |
# | name       | varchar(255) | NO   | UNI | NULL    |       |
# | created_at | datetime     | YES  |     | NULL    |       |
# | updated_at | datetime     | YES  |     | NULL    |       |
# | employee   | tinyint(1)   | YES  |     | NULL    |       |
# +------------+--------------+------+-----+---------+-------+

  ROLES_WITH_EMPLOYEE_FLAG = {
    :account_mgr                  => true,
    :admin                        => true,
    :agency                       => false,
    :android_distribution_config  => true,
    :customer_service             => false,
    :customer_service_manager     => true,
    :devices                      => true,
    :executive                    => true,
    :file_sharer                  => true,
    :games_editor                 => true,
    :hr                           => true,
    :money                        => true,
    :ops                          => true,
    :optimized_rank_booster       => true,
    :partner                      => false,
    :partner_changer              => true,
    :payops                       => true,
    :payout_manager               => true,
    :products                     => nil, #???
    :reporting                    => true,
    :role_mgr                     => true,
    :sales_rep_mgr                => true,
    :tools                        => true
  }

  def self.run!
    ROLES_WITH_EMPLOYEE_FLAG.each_pair do |name, e|
      UserRole.find_or_create_by_name(name, :employee => e)
      Rails.logger.debug "Added #{e ? 'employee ' : ''}role #{name}"
    end
    roles = ::UserRole.all.map(&:name)
    Authorization::Engine.instance.roles.each do |role|
      Rails.logger.warn "No record for role #{role}!" unless UserRole.find_by_name(role)
    end
  end

end
