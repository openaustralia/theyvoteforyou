# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 2.2.0"

vm_hostname = "local-publicwhip.example.com"

Vagrant.configure("2") do |config|

  # provider-specific config
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048 # in MB
    vb.cpus = 2
    vb.linked_clone = false
    vb.name = vm_hostname
  end

  config.vm.hostname = vm_hostname
  config.vm.box_check_update = true

  # Use most recent Ubuntu LTS
  config.vm.box = "generic/ubuntu2004"

  # guest VM directories
  work_base_dir = '/opt'
  work_source_dir = "#{work_base_dir}/source"
  ansible_venv_dir = "#{work_base_dir}/ansible-venv"

  # synchronised directory
  rsync_exclude = %w[.vagrant/ .vscode/ .idea/]
  config.vm.synced_folder "./", work_source_dir, type: 'rsync', rsync__exclude: rsync_exclude, group: 'vagrant', owner: 'vagrant', create: true

  # Set this to a local ubuntu mirror to speed up the apt package installations.
  # Find your local mirrors here: https://launchpad.net/ubuntu/+archivemirrors
  old_apt_url = 'http://us.archive.ubuntu.com/ubuntu'
  new_apt_url = 'https://mirror.internet.asn.au/pub/ubuntu/archive'
  ubuntu_release = 'focal'

  # install ansible
  config.vm.provision "install_ansible", type: "shell", inline: <<-SHELL
    # vagrant might require a /vagrant directory
    if [[ ! -d "/vagrant" ]]; then
      sudo mkdir -p /vagrant
      sudo chown vagrant:vagrant /vagrant
    fi

    # always update apt packages
    sudo DEBIAN_FRONTEND=noninteractive apt-get -yq update

    # ensure ca-certificates is up to date so that https connections will work
    sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install ca-certificates

    # update apt source to a local mirror to speed up the first apt update
    if [[ -f /etc/apt/sources.list && $(grep "#{old_apt_url}" /etc/apt/sources.list) ]]; then
      sudo sed -i 's;#{old_apt_url};#{new_apt_url};g' '/etc/apt/sources.list'
      sudo DEBIAN_FRONTEND=noninteractive apt-get -yq update
    fi
    if [[ -f /etc/apt/sources.list.save && $(grep "#{old_apt_url}" /etc/apt/sources.list.save) ]]; then
      sudo sed -i 's;#{old_apt_url};#{new_apt_url};g' '/etc/apt/sources.list.save'
    fi

    # provide Python 3.9
    if [ ! -f "/etc/apt/sources.list.d/deadsnakes-ubuntu-ppa-#{ubuntu_release}.list" ]; then
      sudo DEBIAN_FRONTEND=noninteractive apt-get -yq upgrade
      sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install software-properties-common python3-apt python-apt-common python3-packaging apt-transport-https
      sudo DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:deadsnakes/ppa
    fi

    # create a Python virtual env for ansible
    if [ ! -d "#{ansible_venv_dir}" ]; then
      sudo DEBIAN_FRONTEND=noninteractive apt-get -yq update
      sudo DEBIAN_FRONTEND=noninteractive apt-get -yq upgrade
      sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install python3.9 python3.9-dev python3.9-venv python3.9-distutils
      sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install libxml2-dev libxslt-dev zlib1g-dev libffi-dev
      sudo python3.9 -m venv #{ansible_venv_dir}
      sudo chown -R vagrant:vagrant #{ansible_venv_dir}
    fi

    sudo DEBIAN_FRONTEND=noninteractive apt-get -yq upgrade
    sudo DEBIAN_FRONTEND=noninteractive apt-get -yq autoremove
    sudo DEBIAN_FRONTEND=noninteractive apt-get -yq autoclean

    #{ansible_venv_dir}/bin/python -m pip install -U pip
    #{ansible_venv_dir}/bin/pip install -U setuptools wheel
    #{ansible_venv_dir}/bin/pip install -U lxml
    #{ansible_venv_dir}/bin/pip install -U ansible

    #{ansible_venv_dir}/bin/ansible-galaxy collection install --upgrade community.general
  SHELL

  # port specifications
  port_mysql = 3306
  port_adminer = 8888
  port_elasticsearch_http = 9200
  port_elasticsearch_nodes = 9300
  port_dejavu = 1358
  port_http_rails = 3000
  port_http_mail = 1080
  port_http_reload = 35729

  # run ansible
  config.vm.provision "run_ansible", type: "ansible_local" do |ans|
    ans.compatibility_mode = "2.0"
    ans.verbose = false
    ans.install = false
    ans.playbook_command = "#{ansible_venv_dir}/bin/ansible-playbook"
    ans.config_file = "#{work_source_dir}/local_dev/ansible.cfg"
    ans.playbook = "#{work_source_dir}/local_dev/playbook.yml"
    ans.extra_vars = {
      work_base_dir: work_base_dir,
      work_source_dir: work_source_dir,

      # forwarded ports
      port_mysql: port_mysql,
      port_adminer: port_adminer,
      port_elasticsearch_http: port_elasticsearch_http,
      port_elasticsearch_nodes: port_elasticsearch_nodes,
      port_dejavu: port_dejavu,
      port_http_rails: port_http_rails,
      port_http_mail: port_http_mail,
      port_http_reload: port_http_reload,

      # set the time zone
      time_zone: 'Australia/Sydney',

      # hard-coded passwords / secrets
      # WARING: These passwords and secrets are hard-coded because this should be fine in a development environment.
      # Change these before running `vagrant up` if you want to use your own local, secure, settings.
      mysql_root_password: 'INSECURE-PASSWORD-IsztHxGhtcCy4Ebo-m0up97BL3ZIGsE34WkfMu4u',
      rails_dev_secret_key_base: 'aa0277cec08c6369786be25e1a2e96929e724528ea30ca0a73d53e490a5bf9e3334efa23edb091c4edcd8c02737af6ec7ae3d5a2709993d55226c6db2f1bd1a3',
      rails_dev_secret_key: 'ed7a1cc2576daf4a432030839f0b974a21e1a9c5dd2b6d0bca27738b3485b93a79a1f60be7cdf3dd96e656a655802d3f9a72079882bd28b6a5aecf55db40ecf7',
      rails_test_secret_key_base: '17c7e185df60114a89a54cdb1b57cc651152d98b452e30d9614a87ac99ce8994c1fd5d8d3c8ac93e20493415d1f45a04c4fa1a1cc3d023257fc25c96c24b9c81',
      rails_test_secret_key: '68f2b4836d6583f92df486fd6b106decb9c3253e42dbe8d16444c8854236e39e053876bf33e30576a91eb3687ae8803cb467dbd1e697b69025566d77389a6be1',
    }
  end

  # forwarded ports
  config.vm.network "forwarded_port", guest: port_mysql, host: port_mysql
  config.vm.network "forwarded_port", guest: port_adminer, host: port_adminer
  config.vm.network "forwarded_port", guest: port_elasticsearch_http, host: port_elasticsearch_http
  config.vm.network "forwarded_port", guest: port_dejavu, host: port_dejavu
  config.vm.network "forwarded_port", guest: port_http_rails, host: port_http_rails
  config.vm.network "forwarded_port", guest: port_http_mail, host: port_http_mail
  config.vm.network "forwarded_port", guest: port_http_reload, host: port_http_reload
end
