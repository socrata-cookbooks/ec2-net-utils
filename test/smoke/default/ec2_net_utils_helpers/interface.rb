# encoding: utf-8
# frozen_string_literal: true

require 'aws-sdk'
require 'timeout'

class EC2NetUtilsHelpers
  class Interface
    class << self
      #
      # Create and tag the secondary interface unless it already exists.
      #
      def create!
        return if created?

        EC2.clone_interface!(Instance.eth0, description)
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

        print "Deleting ENI (#{interface.id})..."
        interface.delete
        # There is ~a second or so where the API can still find the ENI even
        # though it's "deleted".
        sleep(3)
        @interface = nil
        puts 'OK'
      end

      #
      # If the secondary interface is not attached, send an attach call and
      # wait for its status to switch to "in-use".
      #
      def attach!
        return if attached?

        interface.attach(instance_id: Instance.id, device_index: 1)
        print "Waiting for ENI (#{interface.id}) to attach..."
        interface.wait_until(max_attempts: 10,
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

        interface.detach
        print "Waiting for ENI (#{interface.id}) to detach..."
        interface.wait_until(max_attempts: 40,
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
        Instance.ifup!('eth1')
      end

      #
      # Use Inspec to bring down the secondary interface on the instance if
      # it's currently up.
      #
      def ifdown!
        Instance.ifdown!('eth1')
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

      private

      #
      # Fetch and return the secondary interface or nil if it doesn't exist.
      #
      # @return [Aws::EC2::NetworkInterface,NilClass] the secondary interface
      #
      def interface
        EC2.find_interface(description)
      end

      #
      # Construct a unique name for the secondary interface so we can find it
      # easily in the EC2 API.
      #
      def name
        "ec2-net-utils-kitchen-#{Instance.id}-eth1"
      end

      #
      # Construct a unique description for the secondary interface so we can
      # find it easily in the EC2 API.
      #
      def description
        "Test Kitchen ec2-net-utils secondary ENI for #{Instance.id}"
      end
    end
  end
end
