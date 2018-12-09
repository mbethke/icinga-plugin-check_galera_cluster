#!/usr/bin/perl
use strict;
use warnings;
use Monitoring::Plugin;
use DBI;

my $mp = Monitoring::Plugin->new(
    shortname => 'GALERA_CLUSTER',
    usage => "Usage: %s -H|--host HOST [-u USER] [-p PASSWORD] [-P PORT] [-w SIZE] [-c SIZE] [-f FLOAT]",
    version => '0.1',
    #url => '',
    blurb => 'Check health of a Galera cluster',
);

$mp->add_arg( spec => 'host|H=s', help => q(Hostname to check), required => 1 );
$mp->add_arg( spec => 'user|u=s', help => q(Username for MySQL login), required => 0 );
$mp->add_arg( spec => 'pass|p=s', help => q(Password for MySQL login), required => 0 );
$mp->add_arg( spec => 'port|P=s', help => q(TCP port MySQL is listening on), required => 0, default => 3306 );
$mp->add_arg( spec => 'warn|w=n', help => q(Warn at this many cluster nodes), required => 0, default => 3 );
$mp->add_arg( spec => 'crit|c=n', help => q(Go critical at this many cluster nodes), required => 0, default => 2 );
$mp->add_arg( spec => 'flow|f=f', help => q(Critical value of wsrep_flow_control_paused (default is 0.1)), required => 0, default => 0.1 );
$mp->add_arg( spec => 'primary|0', help => q(Go critical if the node is not the primary), required => 0 );
$mp->getopts;

my $opts = $mp->opts;

my $host = $opts->host;
my $port = $opts->port;
my $warn = $opts->warn;
my $crit = $opts->crit;
my $flow = $opts->flow;
my $prim = $opts->primary;

my $dbh = DBI->connect("DBI:mysql:host=$host;port=$port", $opts->user, $opts->pass, { RaiseError => 1 })
    or $mp->plugin_exit( CRITICAL, "Could not connect to host: " . $DBI::errstr);

my %status =
map { @$_ }
grep { $_->[0] =~ /^wsrep_/ }
@{$dbh->selectall_arrayref('SHOW STATUS')};

if($status{wsrep_cluster_size} <= $crit) {
    $mp->add_message(CRITICAL, "number of cluster nodes: $status{wsrep_cluster_size} <= $crit");
} elsif($status{wsrep_cluster_size} <= $warn) {
    $mp->add_message(WARNING, "number of cluster nodes: $status{wsrep_cluster_size} <= $warn");
} else {
    $mp->add_message(OK, "number of cluster nodes: $status{wsrep_cluster_size}");
}
$status{wsrep_flow_control_paused} > $flow
    and $mp->add_message(CRITICAL, "wsrep_flow_control_paused is $status{wsrep_flow_control_paused} > $flow");
$prim and $status{wsrep_cluster_status} ne 'Primary'
    and $mp->add_message(CRITICAL, "node is not primary");
$status{wsrep_ready} ne 'ON'
    and $mp->add_message(CRITICAL, "node is not ready");
$status{wsrep_connected} ne 'ON'
    and $mp->add_message(CRITICAL, "node is not connected");
$status{wsrep_local_state_comment} ne 'Synced'
    and $mp->add_message(CRITICAL, "node is not synced");

$mp->plugin_exit( $mp->check_messages );
