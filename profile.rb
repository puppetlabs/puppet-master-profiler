#!/usr/bin/env ruby
#
# Puppet Master Profile Script
# Author: Britt Gresham <britt@puppetlabs.com>
# Date: 09/18/2014
#
# This script is used to provide Puppet Labs with information regarding the
# setup of the puppet master in order to find areas where the puppet master is
# doing more work than it should.

require 'yaml'
require 'pp'

# Helper Functions

def continue_or_exit(msg, default='n', exit_condition='n')
  puts msg
  if default.downcase == 'n'
    print "[y/N]"
  elsif default.downcase == 'y'
    print "[Y/n]"
  else
    print "[y/n]"
  end
  print ": "
  response = $stdin.gets.chomp
  if response.length == 0
    response = default
  end
  response == exit_condition.downcase
end

def gather_facts(wanted_facts, facter_command='facter')
  facts = {}
  o = `#{facter_command}`
  o.each_line {|fact|
    fact = fact.split(" => ")
    if wanted_facts.include? fact[0].strip
      facts[fact[0]] = fact[1].strip
    end
  }

  facts
end

def puppet_master_config(config)
  o = `puppet master --configprint #{config}`
  o.strip
end

def get_module_count()
  module_paths = puppet_master_config("modulepath").split(":")
  module_count = 0
  module_paths.each {|module_path|
    module_count += Dir.glob(File.join(module_path, "**")).count
  }
  module_count
end

def get_cert_count()
  cert_paths = puppet_master_config("certdir").split(":")
  cert_count = 0
  cert_paths.each {|cert_path|
    cert_count += Dir.glob(File.join(cert_path, "**")).count
  }
  cert_count
end

# Start of profile gathering script

def main profile_log
  # Script options
  profile_log = File.absolute_path(profile_log)
  profile_output_file = File.absolute_path("./profile.yml")

  puts "This script is used to provide Puppet Labs with information regarding the"
  puts "setup of the puppet master in order to find areas where we can improve the"
  puts "puppet masters capacity."
  puts
  puts "We will create a file named #{profile_output_file} with the following information in it:"
  puts "    - Hardware Specs (OS, RAM, Swap, CPU, Virtual/Physical, Kernel, ect.)"
  puts "    - Ruby Version and Puppet/Facter/Hiera Versions"
  puts "    - Puppet Module Count on Master"
  puts "    - If the Node Classifier is being used on the Master"
  puts "    - Hiera complexity (How deep the hierarchical tree is)"
  puts "    - Puppet Master profile data if applicable"
  puts "    - Estimated Managed Node Count (using number of certs)"
  puts
  if !continue_or_exit("Do you wish to continue and have the script generate a #{profile_output_file} file? ", "y", "y")
    abort("Script canceled by user.")
  end
  puts
  puts "--------------------------------------------------"

  answers = {}

  # Gather Profile Data

  puts "Gathering Profile Data from '#{profile_log}'"
  if !File.exist?(profile_log)
    abort("File '#{profile_log}' does not exist.")
  end
  lines = []
  File.open(profile_log).each_line do |line|
    if line =~ /PROFILE/
      lines.push(line)
    end
  end
  answers["profile_data"] = lines.join("\n")

  # Gather system facts

  puts "Gathering Hardware specs from Facter..."
  answers['facter'] = gather_facts [
    "architecture",
    "facterversion",
    "hardwareisa",
    "hardwaremodel",
    "is_virtual",
    "kernel",
    "kernelversion",
    "memoryfree_mb",
    "memorysize_mb",
    "os",
    "processors",
    "puppetversion",
    "rubyversion",
    "swapfree_mb",
    "swapsize_mb",
    "virtual",
  ]

  # Get puppet module count
  # Helps us get a rough idea of how much Puppet is being used.

  puts "Gathering modules count"
  answers['module_count'] = get_module_count

  puts "Gathering certificate count"
  answers['cert_count'] = get_cert_count

  # Using a node classifier?

  puts "Gathering Node Classifier details"
  answers['node_classifier'] = puppet_master_config("node_terminus")

  puts "--------------------------------------------------"

  # Approximate Number of nodes
  puts
  puts "About how many nodes does this master manage?"
  print "Enter a number: "
  answers["user_nodes"] = $stdin.gets.chomp
  puts

  #while continue_or_exit("Would you like us to add additional profiles from a node you specify?", "n", "y")
  #  puts "Please specify a node name to profile"
  #  print "Node name: "
  #  node_name = $stdin.gets.chomp
  #  puts "Compiling a catalog"
  #end

  ymlfile = File.open(profile_output_file, "w")
  ymlfile.write(answers.to_yaml)
  ymlfile.close()

  puts "--------------------------------------------------"
  puts
  puts "A yaml file with your profile data has been put at #{profile_output_file}."
  puts
  puts "Please email this file to 'britt@puppetlabs.com' along with any additional"
  puts "information you would like to include."
  puts
  puts "--------------------------------------------------"

end

doc = <<-DOC
Puppet Labs Puppet Master Profile Script
Author: Britt Gresham <britt@puppetlabs.com>
Date: 09/18/2014

This script is used to provide Puppet Labs with information regarding the
setup of the puppet master in order to find areas where the puppet master is
doing more work than it should.

Usage:
  #{__FILE__} <master_log>
  #{__FILE__} -h | --help

Options:
  -h --help                 Display this screen
DOC

# Argument Parser
begin
  if ARGV.length != 1
    puts doc
    exit(1)
  elsif ARGV[0] == '-h' || ARGV[0] == '--help'
    puts doc
    exit(0)
  end
  main ARGV[0]
end

