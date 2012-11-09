metadata :name => "provision",
         :description => "Information about the server provisioner",
         :author => "R.I.Pienaar",
         :license => "Apache 2.0",
         :version => "1.1",
         :url => "http://mcollective-plugins.googlecode.com/",
         :timeout => 1

dataquery :description => "Provisioner Status" do
    output :locked,
           :description => "Is the provisioner currently locked",
           :display_as  => "Locked",
           :default     => true

    output :disabled,
           :description => "Is the provisioner currently disabled",
           :display_as  => "Disabled",
           :default     => true
end
