# encoding: utf-8
# frozen_string_literal: true

require_relative 'inspec'

class EC2NetUtilsHelpers
  class Instance
    class << self
      attr_reader :id

      #
      # Wait up to 60 seconds for the instance to bring up an interface. Our
      # udev rules bring it up automatically when it's attached so we don't
      # actually have to run `ifup`.
      #
      # It takes several seconds after the ENI is attached before the instance
      # recognizes it and brings it up.
      #
      # @param nic [String] the eth* name of the interface to bring up
      #
      def ifup!(nic)
        return if up?(nic)

        print 'Waiting for instance to bring up ENI as eth1...'
        Timeout.timeout(20) do
          Kernel.loop do
            up?(nic) ? break : print('.')
            sleep(3)
          end
        end
        puts 'OK'
      end

      #
      # Use Inspec to bring down an interface on the instance if it's currently
      # up.
      #
      # @param nic [String] the eth* name of the interface to bring down
      #
      def ifdown!(nic)
        Inspec.command("ifdown #{nic}").stdout if up?(nic)
      end

      #
      # Use Inspec to check with the instance and determine whether an
      # interface is up or not, as determined by `ethtool`.
      #
      # @param nic [String] the eth* name of the interface to check
      #
      # @return [TrueClass,FalseClass] whether the interface is up
      #
      def up?(nic)
        Inspec.command("ethtool #{nic}").exit_status.zero?
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

      private

      #
      # Fetch and cache the instance object representing the EC2 instance
      # under test.
      #
      # @return [Aws::EC2::Instance] the EC2 instance under test
      #
      def instance
        @instance ||= EC2.find_instance(id)
      end

      #
      # Fetch and cache the ID of the EC2 instance under test by using Inspec
      # to run the `ec2metadata` command on the instance.
      #
      # @return [String] the instance ID
      #
      def id
        @id ||= Inspec.command('ec2metadata --instance-id').stdout.strip
      end
    end
  end
end
