VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Base box to build off, and download URL for when it doesn't exist on the user's system already
  config.vm.box = "ubuntu/trusty64"

  config.vm.provider "virtualbox" do |vbox|
    vbox.name = "ir-primer"
    vbox.memory = 1024
    vbox.cpus = 2
  end

  # Forward a port from the guest to the host, which allows for outside
  # computers to access the VM, whereas host only networking does not.
  config.vm.network "forwarded_port", guest: 8080, host: 8080,
    auto_correct: true

  # Enable provisioning with a shell script.
  config.vm.provision :shell,
    inline: <<-eos
      add-apt-repository ppa:docker-maint/testing
      apt-get update
      apt-get upgrade -y
      apt-get dist-upgrade -y
      apt-get autoremove -y
      apt-get install -y docker.io

      usermod -a -G docker vagrant

      wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py
      python get-pip.py

      /usr/local/bin/pip install -U --pre docker-compose
      yes | /usr/local/bin/pip uninstall requests
      /usr/local/bin/pip install requests==2.4.3

      for IMG in dockerfile/nodejs;
      do
        docker pull $IMG
      done

      cd /vagrant && docker-compose build
    eos
end
