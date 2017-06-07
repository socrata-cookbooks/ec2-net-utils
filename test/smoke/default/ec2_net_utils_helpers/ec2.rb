# encoding: utf-8
# frozen_string_literal: true

require 'aws-sdk'
require 'timeout'

class EC2NetUtilsHelpers
  class EC2
    class << self
      #
      # Create a "clone" of another ENI, giving it the same security groups
      # and subnet and a designated description.
      #
      # @param source_nic [Aws::EC2::NetworkInterface] the source ENI
      # @param description [String] the new ENI's description
      #
      def clone_interface!(source_nic, description)
        client.create_network_interface(
          description: description,
          groups: source_nic.groups.map(&:group_id),
          subnet_id: source_nic.subnet_id
        )
      end

      #
      # Locate and return the instance with the desired ID.
      #
      # @param id [String] the instance ID
      #
      # @return [Aws::EC2::Instance] that ID's instance object
      #
      def find_instance(id)
        Aws::EC2::Instance.new(id, client: client)
      end

      #
      # Find an ENI by its description.
      #
      # @param description [String] the ENI's description
      #
      # @return [Aws::EC2::NetworkInterface,NilClass] the ENI object or nil
      #
      # @raise [RuntimeError] if > 1 interfaces match that description
      #
      def find_interface(description)
        nics = client.describe_network_interfaces(
          filters: [{ name: 'description', values: [description] }]
        ).network_interfaces

        return if nics.empty?

        raise('Something went wildly wrong') unless nics.length == 1
        Aws::EC2::NetworkInterface.new(nics[0].network_interface_id,
                                       client: client)
      end

      private

      #
      # Fetch and cache a connection to the EC2 API, using environment
      # variables for the AWS_REGION, AWS_ACCESS_KEY_ID, and
      # AWS_SECRET_ACCESS_KEY. We assume these vars were already set previously
      # in the Kitchen config.
      #
      # @return [Aws::EC2::Client] the new or cached client object
      #
      def client
        @client ||= Aws::EC2::Client.new(
          region: ENV['AWS_REGION'],
          access_key_id: ENV['AWS_ACCESS_KEY_ID'],
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
        )
      end
    end
  end
end
