class OneOffs
  def self.dev_employees
    self.fix_employee_emails
    self.assign_prod_employees
  end

  private

  def self.fix_employee_emails
    list = {
      'steve.tan@tapjoy.com' => 'steve@tapjoy.com',
      'francisco.gutierrez@tapjoy.com' => 'francisco@tapjoy.com',
      'abir@tapjoy.com' => 'abir.majumdar@tapjoy.com',
      'ian.smith@tapjoy.com' => 'ian@tapjoy.com',
      'amir.manji@tapjoy.com' => 'amir@tapjoy.com',
      'jeff.dickey@tapjoy.com' => 'jeffrey.dickey@tapjoy.com',
    }
    list.each do |old, new|
      em = Employee.find_by_email(old)
      em.email = new
      em.save!
    end
  end

  def self.assign_prod_employees
    team = [

      %w( Jeff        Dickey       0 0 ),
      %w( Bert        Kuo          0 1 ),
      %w( Aaron       Daniel       0 2 ),
      %w( Inderpreet  Singh        1 0 ),
      %w( James       Huang        1 1 ),
      %w( Yohan       Chin         1 2 ),

      %w( Neal        Wiggins      2 0 ),
      %w( Adam        Sumner       2 1 ),
      %w( Dave        Abercrombie  2 2 ),
      %w( Norman      Chan         3 0 ),
      %w( Joey        Pan          3 1 ),
      %w( Francisco   Gutierrez    3 2 ),

      %w( Ryan        Johns        4 0 ),
      %w( Amir        Manji        4 1 ),
      %w( Jia         Feng         4 2 ),
      %w( Stephen     McCarthy     5 0 ),
      %w( Hwan-Joon   Choi         5 1 ),

      %w( Steve       Tan          0 3 ),
      %w( Johnny      Chan         0 4 ),
      %w( Ian         Smith        0 5 ),
      %w( Anil        Chalasani    1 3 ),
      %w( Priya       Pucchakayala 1 4 ),
      %w( Kieran      Boyle        1 5 ),

      %w( Van         Pham         0 6 ),
      %w( Pete        Holiday      0 7 ),
      %w( Abir        Majumdar     0 8 ),
      %w( Michael     Wheeler      1 6 ),
      %w( Jeremy      Chotiner     1 7 ),
      %w( Sean        Callan       1 8 ),

      %w( Deng-Kai    Chen         6 0 ),
      %w( Katherine   Zhang        6 1 ),
      %w( Christopher Farm         6 2 ),
      %w( Craig       Berlingo     6 3 ),
      %w( Linda       Tong         7 0 ),
      %w( John        Gronberg     7 1 ),
      %w( Daniel      Lim          7 2 ),

      %w( Kevin       Tu           8 0 ),
      %w( Shane       Booth        8 1 ),
      %w( Jeffrey     Boyce        8 2 ),
      %w( Stephen     Zito         9 0 ),
      %w( Chris       Portugal     9 1 ),

      %w( Eric        Tipton       4 6 ),
      %w( Brian       Stebar       4 7 ),
      %w( James       Logsdon      4 8 ),
      %w( Brian       Sanders      5 6 ),
    ]
    products_role = UserRole.find_or_create_by_name('products')
    team.each do |data|
      employee = Employee.find_by_first_name_and_last_name(data[0], data[1]) || create_employee(data[0], data[1])
      raise "could not find or create #{data[0]} #{data[1]}" unless employee
      employee.department = 'product'
      employee.location = data.slice(2, 2)
      employee.save!
      unless employee.user.nil?
        employee.user.user_roles << products_role
      end
    end
  end

  def self.create_employee(first_name, last_name)
    Employee.create(
      :first_name => first_name,
      :last_name  => last_name,
      :title => 'engineer',
      :email => "#{first_name.downcase}.#{last_name.downcase}@tapjoy.com",
      :superpower => '...',
      :current_games => '...',
      :weapon => '...',
      :biography => '...')
  end
end
