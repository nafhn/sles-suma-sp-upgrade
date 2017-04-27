#!/usr/bin/env ruby
# This script takes in a Suse Manager group name as an argument and upgrades
# the servers in that group to the next service pack

require "xmlrpc/client"
require "open-uri"
# require "yaml"
require "ostruct"
require "time"
require "optparse"

# NOTE if you are running these commands from the Ruby console (irb) you may need
#   to pull in the below library as well on some systems
#require "io/console"

# Channel list array constants, these were pulled from Suse Manager manually
#   in order to simplify the script and make it run faster, these values are
#   unlikely to change for the life of the script (SLES 11 SP3 > SP4) and consist
#   of the labels for all base and child channels in a channel set that a SLES server
#   might be upgraded into in the format: array_name = ['base-channel', 'each-child-channel']

Dev_channels = ['clone-dev-sles11-sp4-pool-x86_64', 'clone-dev-sle11-hae-sp4-pool-x86_64', 'clone-dev-sle11-hae-sp4-updates-x86_64', 'clone-dev-sle11-sdk-sp4-pool-x86_64', 'clone-dev-sle11-sdk-sp4-updates-x86_64', 'clone-dev-sles11-sp4-suse-manager-tools-x86_64', 'clone-dev-sles11-sp4-updates-x86_64']
Test_channels = ['clone-test-sles11-sp4-pool-x86_64', 'clone-test-sle11-hae-sp4-pool-x86_64', 'clone-test-sle11-hae-sp4-updates-x86_64', 'clone-test-sle11-sdk-sp4-pool-x86_64', 'clone-test-sle11-sdk-sp4-updates-x86_64', 'clone-test-sles11-sp4-suse-manager-tools-x86_64', 'clone-test-sles11-sp4-updates-x86_64']
Prod_channels = ['clone-prod-sles11-sp4-pool-x86_64', 'clone-prod-sle11-hae-sp4-pool-x86_64', 'clone-prod-sle11-hae-sp4-updates-x86_64', 'clone-prod-sle11-sdk-sp4-pool-x86_64', 'clone-prod-sle11-sdk-sp4-updates-x86_64', 'clone-prod-sles11-sp4-suse-manager-tools-x86_64', 'clone-prod-sles11-sp4-updates-x86_64']

# Set default options/create "options" hash
options = {:group_name => nil, :schedule_time => "earliest", :dry_run => nil}

# Use the ruby parser library to parse command line options
parser = OptionParser.new do|opts|
  opts.banner = "Usage: sles_batch_upgrade.rb [options]"
  opts.on('-g', '--group_name suse_manager_group_name', 'suse_manager_group_name') do |g|
    options[:group_name] = g;
  end

  opts.on('-s', '--schedule_time 2016-03-07T17:59:00', 'iso8601 format: ex. 2016-03-07T17:59:00') do |s|
    options[:schedule_time] = s;
  end

  opts.on('-d', '--dry_run <true|false>', '<true|false>') do |d|
    options[:dry_run] = d;
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end
end

parser.parse!

# Put command line options into variables
group_name = options[:group_name]; schedule_time = Time.iso8601("#{options[:schedule_time]}"); dry_run = options[:dry_run]

if dry_run == nil || group_name == nil
  puts "Please enter all necessary parameters. One of either dry run or group name is missing. "
  exit
else
  puts "Upgrading Suse Manager group: #{group_name} at #{schedule_time} and is it a dry run? #{dry_run}."
end

# This is here for documentation purposes, what a "channel" looks like
# I'm using "ostruct" (openstruct) to create these automagically
# aChannel = Struct.new(:id, :name, :label, :current_base)

# If SLES 11 had a newer version of Ruby... there'd be better ways to do this
@username = `read -p "Suse Manager admin user name: " uid; echo $uid`.chomp
@password = `read -s -p "Password: " password; echo $password`.chomp; puts "\n"

# The next several lines are mostly unmodified from the examples in the Suse Manager
# API documentation
# Put The DNS resolvable hostname or reachable IP of the Suse Manager Server
# OR localhost if running locally from the Suse Manager Server
@MANAGER_URL = "http://localhost/rpc/api"
# @MANAGER_URL = "http://remoteSuseManager/rpc/api"
# User name and password get read in via bash read command above
@MANAGER_LOGIN = @username
@MANAGER_PASSWORD = @password

@client = XMLRPC::Client.new2(@MANAGER_URL)

@key = @client.call('auth.login', @MANAGER_LOGIN, @MANAGER_PASSWORD)

# This returns an array of systems (SID) in the selected group
active_systems_to_upgrade = @client.call('systemgroup.listActiveSystemsInGroup', @key, group_name)

# Do stuff for these systems
active_systems_to_upgrade.each do |asystemid|

  # Grab a list of all potential base channels and drop the resulting hash varible into an array
  s = @client.call('system.listSubscribableBaseChannels', @key, asystemid)
  subscribablebasechannels = s.to_a

  # Loop through each channel grabbed from above Suse Manager call
  subscribablebasechannels.each do |subscribablebasechannel|

    # Turn the channel hash into a struct using the openstruct library
    achannel = OpenStruct.new(subscribablebasechannel)

    # test to see if the channel is the correct one
    if achannel.current_base == 1
      current_base_channel = achannel.label

      # Set channels
      # Case statement to select a key identifier from the channel names
      # The naming scheme used here lended itself to split via "-"
			# Further note that the old channels and new channels used a similar
			# naming scheme
      case current_base_channel.split("-")[2]
      when 'dev'
        working_channel_set = Dev_channels
      when 'test'
        working_channel_set = Test_channels
      when 'prod'
        working_channel_set = Prod_channels
      end

      # Call the upgrade API function
      action_id_of_upgrade = @client.call('system.scheduleDistUpgrade', @key, asystemid, working_channel_set, dry_run, schedule_time)

      puts "#{asystemid} currently in #{current_base_channel}. Moving to #{working_channel_set[0]}. Action ID for upgrade #{action_id_of_upgrade}" # Test statement

    end
  end
end

# Cleanup/logout
@client.call('auth.logout', @key)
