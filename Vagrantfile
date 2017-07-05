# -*- mode: ruby -*-
# vi: set ft=ruby :

# To get the required box image, you can do
#
#    vagrant box add debian/stretch64 --provider libvirt
#
# that is, assuming the libvirt provider is being used. Otherwise
# just miss off --provider libvirt from the command and it'll pull
# and use the virtualbox version instead.
#
# To build the virtual machine do
#
#    vagrant up
#
# from this directory. Then you can
#
#    vagrant ssh
#
# to get a shell. The web site files are all availabl in /vagrant,
# so doing
#
#    cd /vagrant
#    jekyll serve
#
# should get the web site up and running. Then connect to
#
#    http://localhost:4000/
#
# on your host machine and you should be away.
#
# To get rid of the virtual machine simply do
#
#    vagrant destroy
#
# or you can halt it with "vagrant halt" and return later with
# "vagrant up".



# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.

  # ruby and related components in jessie and trusty are just too
  # old to work, but stretch is good.
  config.vm.box = "debian/stretch64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end


  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  config.vm.network "forwarded_port", guest: 4000, host: 4000, host_ip: "127.0.0.1", guest_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.

  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    # vb.gui = true

    # Customize the amount of memory on the VM:
    vb.memory = "1024"
  end

  config.vm.provider "libvirt" do |vm|
    vm.memory = "1024"
  end

  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-SHELL

    echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen

    apt-get update

    # good for debian stretch
    apt-get -y install ruby ruby-dev build-essential
    gem install jekyll twitter httparty

  SHELL
end
