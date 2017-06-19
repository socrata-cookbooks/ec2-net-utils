# encoding: utf-8
# frozen_string_literal: true

require_relative '../resources'

shared_context 'resources::ec2_net_utils' do
  include_context 'resources'

  let(:resource) { 'ec2_net_utils' }
  %i[].each { |p| let(p) { nil } }
  let(:properties) { {} }
  let(:name) { 'default' }

  shared_context 'the :install action' do
  end

  # shared_context 'the :remove action' do
  #   let(:action) { :remove }
  # end

  shared_context 'all default properties' do
  end

  shared_examples_for 'any platform' do
    context 'the :install action' do
      include_context description

      context 'all default properties' do
        include_context description

        it 'installs a ec2_net_utils resource' do
          expect(chef_run).to install_ec2_net_utils(name)
        end

        it 'ensures the udev package is installed' do
          expect(chef_run).to install_package('udev')
        end

        it 'ensures the curl package is installed' do
          expect(chef_run).to install_package('curl')
        end

        it 'creates the ixgbevf modprobe config' do
          f = '/etc/modprobe.d/ixgbevf.conf'
          expect(chef_run).to create_cookbook_file(f)
        end

        it 'creates the rule_generator.functions file' do
          f = '/lib/udev/rule_generator.functions'
          expect(chef_run).to create_file(f).with(mode: '0755')
        end

        it 'creates the write_net_rules file' do
          f = '/lib/udev/write_net_rules'
          expect(chef_run).to create_file(f).with(mode: '0755')
        end

        it 'creates the ec2net-functions file' do
          f = "#{network_scripts_dir}/ec2net-functions"
          expect(chef_run).to create_template(f).with(mode: '0755')
        end

        it 'renders the expected ec2net-functions file' do
          f = "#{network_scripts_dir}/ec2net-functions"
          [
            /^config_file="#{Regexp.escape(dev_config_path)}"$/,
            /^route_file="#{Regexp.escape(dev_route_path || '')}"$/,
            /^route6_file="#{Regexp.escape(dev_route6_path || '')}"$/,
            /^dhclient_file="#{Regexp.escape(dev_dhclient_path || '')}"$/,
            "  cat <<- EOF > ${config_file}\n#{dev_config_format}\nEOF\n"
          ].each do |m|
            expect(chef_run).to render_file(f).with_content(m)
          end
        end

        it 'creates the ec2ifdown file' do
          f = '/sbin/ec2ifdown'
          expect(chef_run).to create_template(f).with(mode: '0755')
        end

        it 'renders the expected ec2ifdown file' do
          f = '/sbin/ec2ifdown'
          r = %r{^\. #{Regexp.escape(network_scripts_dir)}/ec2net-functions$}
          expect(chef_run).to render_file(f).with_content(r)
        end

        it 'creates the ec2ifup file' do
          f = '/sbin/ec2ifup'
          expect(chef_run).to create_template(f).with(mode: '0755')
        end

        it 'renders the expected ec2ifup file' do
          f = '/sbin/ec2ifup'
          r = %r{^\. #{Regexp.escape(network_scripts_dir)}/ec2net-functions$}
          expect(chef_run).to render_file(f).with_content(r)
        end

        it 'creates the ec2ifscan file' do
          expect(chef_run).to create_template('/sbin/ec2ifscan')
            .with(mode: '0755')
        end

        it 'renders the expected ec2ifscan file' do
          r = Regexp.new("^  cfg=\"#{Regexp.escape(network_scripts_dir)}/" \
                         'interfaces\\.d/\\${dev##\\*\/}\\.cfg"$')
          expect(chef_run).to render_file('/sbin/ec2ifscan')
            .with_content(r)
        end

        it 'creates the ec2dhcp.sh file' do
          f = "#{dhclient_scripts_dir}/ec2dhcp.sh"
          expect(chef_run).to create_template(f).with(mode: '0755')
        end

        it 'renders the expected ec2dhcp.sh file' do
          f = "#{dhclient_scripts_dir}/ec2dhcp.sh"
          r = %r{^\. #{Regexp.escape(network_scripts_dir)}/ec2net-functions$}
          expect(chef_run).to render_file(f).with_content(r)
        end

        it 'creates the ENI udev rules file' do
          f = '/etc/udev/rules.d/53-ec2-network-interfaces.rules'
          expect(chef_run).to create_template(f)
        end

        it 'renders the expected ENI udev rules file' do
          f = '/etc/udev/rules.d/53-ec2-network-interfaces.rules'
          r = Regexp.new('^SUBSYSTEM=="net", KERNEL=="eth\\*", ' \
                         "RUN\\+=\"#{Regexp.escape(network_scripts_dir)}/" \
                         'ec2net\\.hotplug"$')
          expect(chef_run).to render_file(f).with_content(r)
        end

        it 'creates the persistent net generator udev rules file' do
          f = '/etc/udev/rules.d/75-persistent-net-generator.rules'
          expect(chef_run).to create_cookbook_file(f)
        end

        it 'creates the ec2net.hotplug file' do
          f = "#{network_scripts_dir}/ec2net.hotplug"
          expect(chef_run).to create_template(f).with(mode: '0755')
        end

        it 'renders the expected ec2net.hotplug file' do
          f = "#{network_scripts_dir}/ec2net.hotplug"
          r = %r{^\. #{Regexp.escape(network_scripts_dir)}\/ec2net-functions$}
          expect(chef_run).to render_file(f).with_content(r)
        end

        %w[ec2ifdown ec2ifscan ec2ifup].each do |f|
          it "creates the #{f} man page file" do
            f = "/usr/share/man/man8/#{f}.8.gz"
            expect(chef_run).to create_cookbook_file(f)
          end
        end
      end
    end
  end
end
