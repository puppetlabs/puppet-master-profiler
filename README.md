Puppet Master Profile Script
============================

**Note: The `--profile` flag was added in Puppet 3.2.0. This script will not work in Puppet before 3.2.0**

The puppet master profile script generates a profile.yml file that includes information
about how a master is running.

How to use
----------

  1. Download the repository and place the `profile.rb` on the puppet master.
  2. Start (or restart) your master with the `debug` and `profile` options
    enabled. Set the `logdest` to a location of an empty file so that only the
    profile data will be added.
  3. After running your puppet master like this for a few agent check-ins run
    the `profile.rb` script and pass in the log file outputted by puppet master
    as an argument.
  4. Follow the on screen prompts to generate the profile.yml file.
  5. Email this file to [britt@puppetlabs.com](mailto:britt@puppetlabs.com).

I run my environment in a Master-less Environment
-------------------------------------------------

You can help too! Instead of running puppet master and waiting for a few agents
to check in pass in the same flags into `puppet apply` you will get profile
logs for a catalog compiled for the node.

Running `puppet apply --debug --profile --logdest=./profile.log
/etc/puppet/some/manifest.pp` It will give you a log file at `./profile.log`
for the catalog created for the `/etc/puppet/some/manifest.pp` You can then
pass that profile.log into the script to generate the profile file.

About the Information
---------------------

The information collected should not contain any identifiable information but
information about the system itself. The script collects this information using
Facter and Puppet.

The information collected is listed below.

  - Facter Facts Collected
    - architecture
    - facterversion
    - hardwareisa
    - hardwaremodel
    - is_virtual
    - kernel
    - kernelversion
    - memoryfree_mb
    - memorysize_mb
    - os
    - processors
    - puppetversion
    - rubyversion
    - swapfree_mb
    - swapsize_mb
    - virtual
  - Puppet Module Count
  - Number of Certificates
  - Type of Node Classifier Used
  - Approximate Number of Nodes managed by Puppet Master
  - Puppet Master Profile Data
