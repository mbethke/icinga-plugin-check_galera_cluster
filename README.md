icinga-plugin-check_galera_cluster
=======================================

An Icinga plugin in Perl to check the health of a Galera cluster

Inspired by [Guillaume Coré's Bash
plugin](https://github.com/fridim/nagios-plugin-check_galera_cluster)
but many times faster due to Icinga's embedded Perl interprete .

Options:

  `--host -H`
    Host to check. This is the only obligatory argument, although you will
    typically need `--user` and `--pass` as well.

  `--user -u`
    MySQL user.

  `--pass -p`
    MySQL password.

  `--port -P`
    MySQL port (default: 3306).

  `--warn -w`
    Number of cluster nodes that will cause a WARNING (default: 2)

  `--crit -c`
    Number of cluster nodes that will cause a CRITICAL (default: 1)

  `--float -f`
    Raise a CRITICAL if wsrep_flow_control_paused is above this value (default: 0.1).

  `--primary|-0`
    Raise a CRITICAL if this node is not the primary
