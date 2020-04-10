require 'ipaddr'
#require 'yaml'

ENV["LC_ALL"] = 'en_US.utf8'

# vm configuraton
start_ip      = '10.20.40.50'
powa_server   = 'powa'
pg_servers    = [ 'pgsql1', 'pgsql2' ]

# pg configuration
pgver         = 11

Vagrant.configure(2) do |config|

    nodes_ips  = {}
    powa_ip    = start_ip
    next_ip    = IPAddr.new(start_ip).succ

    ( pg_servers ).each do |node|
        nodes_ips[node] = next_ip.to_s
        next_ip = next_ip.succ
    end

    # don't mind about insecure ssh key
    config.ssh.insert_key = false

    # https://vagrantcloud.com/search.
    config.vm.box = 'centos/7'

    # hardware and host settings
    config.vm.provider 'libvirt' do |lv|
        lv.cpus = 1
        lv.memory = 512
        lv.watchdog model: 'i6300esb'
        lv.default_prefix = 'powa'
        lv.qemu_use_session = false
    end

    # disable default share
    config.vm.synced_folder ".", "/vagrant", disabled: false

    # powa setup
    config.vm.define powa_server do |powa_setup|
        powa_setup.vm.network 'private_network', ip: powa_ip
	powa_setup.vm.hostname = powa_server

	args = []
	(pg_servers).each do |p|
            args.push("-p", "#{p}=#{nodes_ips[p]}")
        end

	powa_setup.vm.provision 'powa-postgresql-setup', type: 'shell',
	    path: 'provision/postgresql.bash',
	    args: [ '-v', '11' ],
	    preserve_order: true

	powa_setup.vm.provision 'powa-powa-client-setup', type: 'shell',
	    path: 'provision/powa-client.bash',
	    args: [ '-v', '11' ],
	    preserve_order: true

	powa_setup.vm.provision 'powa-web-setup', type: 'shell',
	    path: 'provision/powa-web.bash',
	    args: [ '-v', '11' ] + args,
	    preserve_order: true
    end

    # setup postgresql nodes
    ( pg_servers ).each do |node|
	config.vm.define node do |pg_setup|
	    pg_setup.vm.network 'private_network', ip: nodes_ips[node]
	    pg_setup.vm.hostname = node

	    pg_setup.vm.provision 'pg-postgresql-setup', type: 'shell',
		path: 'provision/postgresql.bash',
		args: [ '-v', '11' ],
	        preserve_order: true

	    pg_setup.vm.provision 'pg-powa-client-setup', type: 'shell',
		path: 'provision/powa-client.bash',
		args: [ '-v', '11' ],
	        preserve_order: true
	end
    end
end
