#!/usr/bin/env perl

# FPM - FreeBSD Package Manager (apt-style wrapper)
# Usage: fpm [command] [options] [package]

use strict;
use warnings;
use Getopt::Long;
use File::Basename;

my $VERSION = "1.0.0";
my $HISTORY_FILE = "/var/log/fpm_history.log";

# Command line options
my $auto_confirm = 0;
my $verbose = 0;
my $help = 0;

# Parse global flags
GetOptions(
    "y" => \$auto_confirm,
    "verbose" => \$verbose,
    "v" => \$verbose,
    "help" => \$help,
    "h" => \$help
) or usage(1);

# Main command processing
my $command = shift @ARGV || '';

if ($help || $command eq 'help') {
    usage(0);
}

if ($command eq '--version' || $command eq 'version') {
    print "FPM (FreeBSD Package Manager) version $VERSION\n";
    exit 0;
}

# Execute the appropriate command
given ($command) {
    when ('update')    { fpm_update(); }
    when ('upgrade')   { fpm_upgrade(); }
    when ('install')   { fpm_install(); }
    when ('remove')    { fpm_remove(); }
    when ('delete')    { fpm_remove(); } # alias for remove
    when ('find')      { fpm_find(); }
    when ('search')    { fpm_find(); }   # alias for find
    when ('id')        { fpm_id(); }
    when ('info')      { fpm_id(); }     # alias for id
    when ('list')      { fpm_list(); }
    when ('autoremove') { fpm_autoremove(); }
    when ('history')   { fpm_history(); }
    when ('')          { usage(1); }
    default            { 
        print "Error: Unknown command '$command'\n";
        usage(1);
    }
}

exit 0;

# Command implementations
sub fpm_update {
    log_history("update", "");
    print "Updating package repository catalog...\n" if $verbose;
    my $cmd = "pkg update";
    system($cmd);
    my $exit_code = $? >> 8;
    if ($exit_code != 0) {
        die "Error: Failed to update repositories (exit code: $exit_code)\n";
    }
}

sub fpm_upgrade {
    log_history("upgrade", "");
    print "Upgrading all installed packages...\n" if $verbose;
    
    my $cmd = "pkg upgrade";
    if ($auto_confirm) {
        $cmd .= " -y";
    }
    
    system($cmd);
    my $exit_code = $? >> 8;
    if ($exit_code != 0) {
        die "Error: Failed to upgrade packages (exit code: $exit_code)\n";
    }
}

sub fpm_install {
    my @packages = @ARGV;
    unless (@packages) {
        die "Error: No packages specified for installation.\nUsage: fpm install <package1> [package2 ...]\n";
    }
    
    my $package_list = join(' ', @packages);
    log_history("install", $package_list);
    
    print "Installing packages: @packages\n" if $verbose;
    
    my $cmd = "pkg install @packages";
    if ($auto_confirm) {
        $cmd .= " -y";
    }
    
    system($cmd);
    my $exit_code = $? >> 8;
    if ($exit_code != 0) {
        die "Error: Failed to install packages (exit code: $exit_code)\n";
    }
}

sub fpm_remove {
    my @packages = @ARGV;
    unless (@packages) {
        die "Error: No packages specified for removal.\nUsage: fpm remove <package1> [package2 ...]\n";
    }
    
    my $package_list = join(' ', @packages);
    log_history("remove", $package_list);
    
    print "Removing packages: @packages\n" if $verbose;
    
    my $cmd = "pkg delete @packages";
    if ($auto_confirm) {
        $cmd .= " -y";
    }
    
    system($cmd);
    my $exit_code = $? >> 8;
    if ($exit_code != 0) {
        die "Error: Failed to remove packages (exit code: $exit_code)\n";
    }
}

sub fpm_find {
    my @search_terms = @ARGV;
    unless (@search_terms) {
        die "Error: No search terms specified.\nUsage: fpm find <search_term>\n";
    }
    
    my $search_term = join(' ', @search_terms);
    print "Searching for: $search_term\n" if $verbose;
    
    my $cmd = "pkg search $search_term";
    system($cmd);
    
    my $exit_code = $? >> 8;
    if ($exit_code != 0) {
        die "Error: Search failed (exit code: $exit_code)\n";
    }
}

sub fpm_id {
    my @packages = @ARGV;
    unless (@packages) {
        die "Error: No package specified.\nUsage: fpm id <package>\n";
    }
    
    foreach my $package (@packages) {
        print "Showing information for: $package\n" if $verbose && @packages > 1;
        my $cmd = "pkg info $package";
        system($cmd);
        
        my $exit_code = $? >> 8;
        if ($exit_code != 0) {
            warn "Error: Could not get information for '$package' (exit code: $exit_code)\n";
        }
        
        print "\n" if @packages > 1;
    }
}

sub fpm_list {
    print "Listing all installed packages...\n" if $verbose;
    system("pkg info");
    
    my $exit_code = $? >> 8;
    if ($exit_code != 0) {
        die "Error: Failed to list packages (exit code: $exit_code)\n";
    }
}

sub fpm_autoremove {
    log_history("autoremove", "");
    print "Removing orphaned dependencies...\n" if $verbose;
    
    my $cmd = "pkg autoremove";
    if ($auto_confirm) {
        $cmd .= " -y";
    }
    
    system($cmd);
    my $exit_code = $? >> 8;
    if ($exit_code != 0) {
        die "Error: Failed to remove orphaned packages (exit code: $exit_code)\n";
    }
}

sub fpm_history {
    unless (-e $HISTORY_FILE) {
        print "No FPM history found.\n";
        return;
    }
    
    open my $fh, '<', $HISTORY_FILE or die "Error: Cannot read history file: $!\n";
    
    print "FPM Command History:\n";
    print "=" x 50 . "\n";
    
    while (my $line = <$fh>) {
        chomp $line;
        my ($timestamp, $command, $packages) = split(/\|/, $line);
        printf "%-20s %-12s %s\n", $timestamp, $command, $packages;
    }
    
    close $fh;
}

# Helper functions
sub log_history {
    my ($action, $packages) = @_;
    
    # Ensure log directory exists
    my $log_dir = dirname($HISTORY_FILE);
    system("mkdir -p $log_dir") unless -d $log_dir;
    
    my $timestamp = `date '+%Y-%m-%d %H:%M:%S'`;
    chomp $timestamp;
    
    open my $fh, '>>', $HISTORY_FILE or warn "Warning: Cannot write to history file: $!\n" and return;
    print $fh "$timestamp|$action|$packages\n";
    close $fh;
}

sub usage {
    my ($exit_code) = @_;
    
    print <<"EOF";
FPM - FreeBSD Package Manager (apt-style wrapper) v$VERSION

Usage: fpm [global options] <command> [package...]

Global Options:
  -y, --yes         Auto-confirm all prompts
  -v, --verbose     Verbose output
  -h, --help        Show this help message

Commands:
  update            Update repository catalog
  upgrade           Upgrade all installed packages
  install <pkg>     Install package(s)
  remove <pkg>      Remove package(s)
  find <term>       Search for packages
  id <pkg>          Show package information
  list              List all installed packages
  autoremove        Remove orphaned dependencies
  history           Show install/update/remove history

Aliases:
  search            Alias for 'find'
  info              Alias for 'id'  
  delete            Alias for 'remove'

Examples:
  fpm update
  fpm install firefox
  fpm remove vim
  fpm upgrade -y
  fpm find nano
  fpm id firefox
  fpm list
  fpm autoremove -y
  fpm history

EOF

    exit $exit_code;
}
