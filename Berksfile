# encoding: utf-8
# frozen_string_literal: true

source 'https://supermarket.chef.io'

metadata

group :unit do
  cookbook 'resource_test', path: 'spec/support/cookbooks/resource_test'
end

group :integration do
  cookbook 'ec2-net-utils_test',
           path: 'test/fixtures/cookbooks/ec2-net-utils_test'
end
