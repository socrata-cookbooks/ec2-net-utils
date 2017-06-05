# encoding: utf-8
# frozen_string_literal: true

require 'aws-sdk'
require 'timeout'

class EC2NetUtilsHelpers
  class SecondaryEni
    class << self
      #
      # Create the secondary interface, attach it to the instance under test,
      # and wait for it to be brought up.
      #
      def set_up!
        create!
        attach!
        ifup!
      end

      #
      # Bring down the secondary interface on the instance, detach it, and
      # delete it.
      #
      def tear_down!
        ifdown!
        detach!
        destroy!
      end

      #
      # Create and tag the secondary interface unless it already exists.
      #
      def create!
        return if created?

        ec2.create_network_interface(
          description: description,
          groups: eth0.groups.map(&:group_id),
          subnet_id: eth0.subnet_id
        ).network_interface
        tag!
        puts "Created secondary ENI (#{interface.id})"
      end

      #
      # Give the secondary interface a name tag so it's easier to find in the
      # UI.
      #
      def tag!
        interface.create_tags(tags: [{ key: 'Name', value: name }])
      end

      #
      # Destroy the secondary interface if it exists.
      #
      def destroy!
        return unless created?

        e = interface
        print "Deleting ENI (#{e.id})..."
        e.delete
        # There is ~a second or where the API can still find the ENI even
        # though it's "deleted".
        sleep(3)
        puts 'OK'
      end

      #
      # If the secondary interface is not attached, send an attach call and
      # wait for its status to switch to "in-use".
      #
      def attach!
        return if attached?

        e = interface
        e.attach(instance_id: instance.id, device_index: 1)
        print "Waiting for ENI (#{e.id}) to attach..."
        e.wait_until(max_attempts: 10,
                     delay: 3,
                     before_wait: proc { print('.') }) do |r|
          r.status == 'in-use'
        end
        puts 'OK'
      end

      #
      # If the secondary interface is attached, send a detach call and wait for
      # its status to switch to "available".
      #
      def detach!
        return unless attached?

        e = interface
        e.detach if e.status == 'in-use'
        print "Waiting for ENI (#{e.id}) to detach..."
        e.wait_until(max_attempts: 40,
                     delay: 3,
                     before_wait: proc { print('.') }) do |r|
          r.status == 'available'
        end
        puts 'OK'
      end

      #
      # Wait up to 60 seconds for the instance to bring up the secondary
      # interface. Our udev rules bring it up automatically when it's attached
      # so we don't actually have to run `ifup`.
      #
      # It takes several seconds after the ENI is attached before the instance
      # recognizes it and brings it up.
      #
      def ifup!
        return if up?

        print 'Waiting for instance to bring up ENI as eth1...'
        Timeout.timeout(20) do
          Kernel.loop do
            break if command('ethtool eth1').exit_status.zero?
            print('.')
            sleep(3)
          end
        end
        puts 'OK'
      end

      #
      # Use Inspec to bring down the secondary interface on the instance if
      # it's currently up.
      #
      def ifdown!
        return unless up?

        command('ifdown eth1').stdout
      end

      #
      # Use the EC2 API to determine whether the secondary interface has been
      # created.
      #
      # @return [TrueClass,FalseClass] whether the interface exists
      #
      def created?
        !interface.nil?
      end

      #
      # Use the EC2 API to check whether the secondary interface is attached.
      #
      # @return [TrueClass,FalseClass] whether the interface is attached
      #
      def attached?
        interface.status == 'in-use'
      end

      #
      # Use Inspec to check with the instance and determine whether the
      # secondary interface is up or not, as determined by `ethtool`.
      #
      # @return [TrueClass,FalseClass] whether the interface is up
      #
      def up?
        command('ethtool eth1').exit_status.zero?
      end

      private

      #
      # Fetch and return the secondary interface or nil if it doesn't exist.
      #
      # @return [Aws::EC2::NetworkInterface,NilClass] the secondary interface
      #
      def interface
        nics = ec2.describe_network_interfaces(
          filters: [{ name: 'description', values: [description] }]
        ).network_interfaces

        return if nics.empty?
        raise('Something went wildly wrong') unless nics.length == 1
        Aws::EC2::NetworkInterface.new(
          nics[0].network_interface_id, client: ec2
        )
      end

      #
      # Construct a unique name for the secondary interface so we can find it
      # easily in the EC2 API.
      #
      def name
        "kitchen-#{instance.id}-eth1"
      end

      #
      # Construct a unique description for the secondary interface so we can
      # find it easily in the EC2 API.
      #
      def description
        "Test Kitchen Secondary ENI for #{instance.id}"
      end

      #
      # Find and return the instance's primary eth0 interface. We'll need it
      # in order to assign eth1 the same subnet and security groups when
      # creating it.
      #
      # @return [Aws::EC2::NetworkInterface]
      #
      def eth0
        instance.network_interfaces.find do |i|
          i.attachment.device_index.zero?
        end
      end

      #
      # Fetch and cache the instance object representing the EC2 instance
      # under test.
      #
      # @return [Aws::EC2::Instance] the EC2 instance under test
      #
      def instance
        @instance ||= Aws::EC2::Instance.new(instance_id, client: ec2)
      end

      #
      # Fetch and cache a connection to the EC2 API, using environment
      # variables for the AWS_REGION, AWS_ACCESS_KEY_ID, and
      # AWS_SECRET_ACCESS_KEY. We assume these vars were already set previously
      # in the Kitchen config.
      #
      # @return [Aws::EC2::Client] the new or cached client object
      #
      def ec2
        @ec2 ||= Aws::EC2::Client.new(
          region: ENV['AWS_REGION'],
          access_key_id: ENV['AWS_ACCESS_KEY_ID'],
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
        )
      end

      #
      # Fetch and cache the ID of the EC2 instance under test by using Inspec
      # to run the `ec2metadata` command on the instance.
      #
      # @return [String] the instance ID
      #
      def instance_id
        @instance_id ||= command('ec2metadata --instance-id').stdout.strip
      end

      #
      # Use Inspec to run a command against the instance under test and return
      # the resulting command object.
      #
      # @param cmd [String] the command to run
      #
      # @return [Inspec::Resources::Cmd] the resulting inspec command object
      #
      def command(cmd)
        EC2NetUtilsHelpers.inspec.command(cmd)
      end
    end
  end
end
