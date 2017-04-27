#### Purpose
Suse Linux enterprise (unlike some other RPM based distros) has the concept of service packs and upgrading between service packs. This has introduced functionality into Suse Manager that requires large amounts of "pointing and clicking" in the GUI for performing service pack upgrades. The API, of course, can be used to work around this, which can be very helpful when performing these actions on thousands of servers.

This Ruby script handles the specific use case of interacting with the Suse Manager API for doing batched upgrades between Suse Manager service packs.

#### Usage and Prerequistes

This script has two major Prerequistes:

1. Ensure the current clone channel label base names match the "new" clone channel base names*
2. Create groups of servers to migrate

\*There are example channel names hard coded in the script

In regards to usage, this is a Ruby script that's run from the command line of the Suse Manager server. Typical command line usage details are provided via the "-h" flag:

```bash
$ ./sles_batch_upgrade.rb -h
Usage: sles_batch_upgrade.rb [options]
    -g suse_manager_group_name,      suse_manager_group_name
        --group_name
    -s 2016-03-07T17:59:00,          iso8601 format: ex. 2016-03-07T17:59:00
        --schedule_time
    -d, --dry_run <true|false>       <true|false>
    -h, --help                       Displays Help
```

All command line flags (other than help) are mandatory and can be given in any order.

#### Testing
This script was used extensively with Suse Manager 2.1 to upgrade SLES 11 SP3 to 4. However, it appears that the issues that lead to the creation of this script persist in Suse Manager 3/SLES 12.
