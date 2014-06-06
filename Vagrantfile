# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
  
  config.vm.provision "shell" do |shell|
  shell.inline = "mkdir -p /etc/puppet/modules;
     puppet module install puppetlabs-apt;
     puppet module install puppetlabs-mysql"
  end
  
  config.vm.provision "puppet" do |puppet|
     puppet.manifests_path = "manifests"
     puppet.manifest_file  = "development_trusty.pp"
  end
end