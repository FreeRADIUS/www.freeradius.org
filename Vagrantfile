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
# and nginx is configured to serve from /srv/www/www.freeradius.org
# (a symlink to the jekyll _site directory).
#
# Ports are forwarded so you can connect to
#
#    http://localhost/
#
# on your host machine and you should be away. Or if you
#
#    cd /vagrant
#    jekyll serve
#
# you can also view the site on
#
#    http://localhost:4000/
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

  config.vm.define :frorg do |frorg|

    # Set a hostname
    #
    frorg.vm.hostname = "frorg"

    # Ruby and related components in jessie and trusty are just too
    # old to work, but stretch is good.
    #
    frorg.vm.box = "debian/stretch64"

    # Cache installed debian packages between rebuilds
    #
    if Vagrant.has_plugin?("vagrant-cachier")
      config.cache.scope = :box
    end

    # For nginx
    #
    frorg.vm.network "forwarded_port", guest: 80, host: 80, host_ip: "127.0.0.1", guest_ip: "127.0.0.1"

    # In case "jekyll serve" is used
    #
    frorg.vm.network "forwarded_port", guest: 4000, host: 4000, host_ip: "127.0.0.1", guest_ip: "127.0.0.1"

    # Copy the infrastructure git repo in for reference only.
    #
    frorg.vm.synced_folder "../infrastructure", "/srv/infrastructure", type: "rsync"
    frorg.vm.synced_folder "../freeradius-server", "/srv/freeradius-server", type: "rsync"

    # Set memory available (though not tested in virtualbox yet)
    #
    frorg.vm.provider :libvirt do |vm|
      vm.memory = 1024
    end

    frorg.vm.provider :virtualbox do |vb|
      vb.memory = 1024
    end

    # Sort out locales
    #
    frorg.vm.provision "shell", inline: <<-SHELL
      sed -i -e 's/# \(en_GB.UTF-8 UTF-8\)$/\1/' /etc/locale.gen
      sed -i -e 's/# \(en_CA.UTF-8 UTF-8\)$/\1/' /etc/locale.gen
      locale-gen
    SHELL

    # Everything else is provisioned with salt. The config is
    # based on the live server salt configs, but dependencies
    # makes it hard to actually use them so these are independent.
    #
    frorg.vm.provision :salt do |salt|
      salt.minion_config = "_vagrant/minion"
      salt.run_highstate = true
      salt.install_type = "stable"
      salt.verbose = true
    end

  end
end

