metadata :name => "Server Provisioning Agent",
	 :description => "Agent to assist in provisioning new servers",
	 :author => "R.I.Pienaar",
	 :license => "Apache 2.0",
	 :version => "1.1",
	 :url => "http://mcollective-plugins.googlecode.com/",
	 :timeout => 360


action "set_puppet_host", :description => "Update /etc/hosts with the master IP" do
	display	:always

    	input :ipaddress,
              :prompt      => "Master IP Address",
              :description => "IP Adress of the Puppet Master",
              :type        => :string,
              :validation  => '^\d+\.\d+\.\d+\.\d+$',
              :optional    => false,
              :maxlength   => 15
end

action "request_certificate", :description => "Send the CSR to the master" do
	output :output,
	       :description => "Puppetd Output",
	       :display_as  => "Output"

	output :exitcode,
	       :description => "Puppetd Exit Code",
	       :display_as  => "Exit Code"
end

action "bootstrap_puppet", :description => "Runs the Puppet bootstrap environment" do
	output :output,
	       :description => "Puppetd Output",
	       :display_as  => "Output"

	output :exitcode,
	       :description => "Puppetd Exit Code",
	       :display_as  => "Exit Code"
end

action "run_puppet", :description => "Runs Puppet in the normal environment" do
	output :output,
	       :description => "Puppetd Output",
	       :display_as  => "Output"

	output :exitcode,
	       :description => "Puppetd Exit Code",
	       :display_as  => "Exit Code"
end

action "has_cert", :description => "Finds out if we already have a Puppet certificate" do
    output :has_cert,
           :description => "Have a puppet certificate already been created",
           :display_as => "Has Certificate"
end

action "lock_deploy", :description => "Lock the deploy so new ones can not be started" do
    output :lockfile,
           :description => "The file that got created",
           :display_as => "Lock file"
end

action "is_locked", :description => "Determine if the install is currently locked" do
    output :locked,
           :description => "Is the install locked",
           :display_as => "Locked"
end
