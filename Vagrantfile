# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # OAF server runs lucid, best to match that environment.
  config.vm.box = "chef/ubuntu-10.04-i386"

  config.vm.network "forwarded_port", guest: 80, host: 8080 # php
  config.vm.network "forwarded_port", guest: 3000, host: 3000 # rails
  config.vm.network "forwarded_port", guest: 1080, host: 1080 # mailcatcher

  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", 1536]
  end

  config.vm.provision "shell" do |shell|
    shell.inline = "mkdir -p /etc/puppet/modules;
     aptitude update
     aptitude safe-upgrade -y

     # Unfortunately we require a reboot to load the new kernel.
     # I should probably update the vm, re-box it and upload it.
     # For the moment you will have to run 'vagrant provision'
     # after rebooting the vm to get virtualbox shared folders working.

     aptitude install -y linux-headers-$(uname -r)
     aptitude install -y virtualbox-ose-dkms

     if [ ! $(which puppet) ] ; then
        wget https://apt.puppetlabs.com/puppetlabs-release-lucid.deb -O /tmp/puppetlabs-release-lucid.deb
        dpkg -i /tmp/puppetlabs-release-lucid.deb
        aptitude update
        aptitude install -y puppet
     fi

     if [ ! -d /etc/puppet/modules/apt ] ; then
        puppet module install puppetlabs-apt
     fi

     if [ ! -d /etc/puppet/modules/mysql ] ; then
        puppet module install puppetlabs-mysql
     fi

     if [ ! -d /etc/puppet/modules/apache ] ; then
        puppet module install puppetlabs-apache
     fi

     if [ ! -d /etc/puppet/modules/rvm ] ; then
        puppet module install maestrodev/rvm
     fi

     if [ ! -d /etc/puppet/modules/timezone ] ; then
        puppet module install saz-timezone
     fi"
  end

  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file = "development_lucid.pp"
  end
end
