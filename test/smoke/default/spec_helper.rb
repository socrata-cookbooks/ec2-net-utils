require 'aws-sdk'
require 'inspec'
require 'timeout'

class Ec2NetUtilsHelpers
  class << self
    attr_reader :inspec

    def configure!(params)
      @inspec = params.fetch(:inspec)
    end

    def configured?
      !instance_id.nil?
    end

    def set_up!
      return if eth1

      resp = ec2.create_network_interface(
        description: "Secondary ENI for #{instance.id}",
        groups: eth0.groups.map(&:group_id),
        subnet_id: eth0.subnet_id
      ).network_interface.network_interface_id
      e = Aws::EC2::NetworkInterface.new(resp, client: ec2)
      e.create_tags(
        tags: [{ key: 'Name', value: "kitchen-#{instance.id}-eth1" }]
      )
      puts "Created secondary ENI (#{e.id})"
      e.attach(instance_id: instance.id, device_index: 1)
      print "Waiting for ENI (#{eth1.id}) to attach..."
      e.wait_until(max_attempts: 10,
                   delay: 3,
                   before_wait: proc { print('.') }) do |r|
        r.status == 'in-use'
      end
      instance.wait_until(max_attempts: 10,
                          delay: 3,
                          before_wait: proc { print('.') }) do |r|
        r.network_interfaces.count == 2
      end
      puts 'OK'
      wait_for_eni_up!
    end

    def tear_down!
      e = eth1

      return if e.nil?

      e.detach if e.status == 'in-use'
      print "Waiting for ENI (#{e.id}) to detach..."
      e.wait_until(max_attempts: 40,
                   delay: 3,
                   before_wait: proc { print('.') }) do |r|
        r.status == 'available'
      end
      puts 'OK'

      print "Deleting ENI (#{e.id})..."
      e.delete
      # There is ~a second or where the API can still find the ENI even
      # though it's "deleted".
      sleep(3)
      puts 'OK'
    end

    def wait_for_eni_up!
      return if inspec.command('ethtool eth1').exit_status.zero?

      # It takes several seconds after the ENI is attached before the instance
      # recognizes it and brings it up.
      print 'Waiting for instance to bring up ENI as eth1...'
      Timeout::timeout(20) do
        while true
          break if inspec.command('ethtool eth1').exit_status.zero?
          print('.')
          sleep(3)
        end
      end
      puts 'OK'
    end

    def eth1
      instance.network_interfaces.find do |i|
        i.attachment.device_index == 1
      end
    end

    def eth0
      instance.network_interfaces.find do |i|
        i.attachment.device_index == 0
      end
    end

    def instance
      Aws::EC2::Instance.new(instance_id, client: ec2)
    end

    def ec2
      @ec2 ||= Aws::EC2::Client.new(region: ENV['AWS_REGION'],
                                    access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                                    secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
    end

    def instance_id
      @instance_id ||= inspec.command('ec2metadata --instance-id').stdout.strip
    end
  end
end


RSpec.configure do |c|
  c.before do
    Ec2NetUtilsHelpers.configure!(inspec: inspec)
    Ec2NetUtilsHelpers.set_up!
  end
end

at_exit do
  if defined?(inspec)
    Ec2NetUtilsHelpers.configure!(inspec: inspec)
    Ec2NetUtilsHelpers.tear_down!
  end
end
