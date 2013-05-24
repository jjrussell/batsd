class OneOffs
  def self.add_generate_invoice_report_job
    Job.create!(
      :active     => true,
      :job_type   => 'master',
      :controller => 'master_generate_invoice_report',
      :action     => 'index',
      :seconds    => '60',
      :frequency  => 'daily'
    )
  end
end
