#!/usr/bin/env perl
use strict;
use Getopt::Long;

my $HOME = $ENV{'HOME'};
my $TS   = time();

my $result = GetOptions(
  'skip-dot-files'    => \my $opt_skip_dot_files,
  'skip-git-dirs'     => \my $opt_skip_git_dirs,
);

################################################################################
#
# DOT FILES
#
################################################################################

unless ($opt_skip_dot_files) {
  my @save_dot_files = qw(.bash_profile .certs .dap_token_passwords.json .gitignore .perforce .profile .s3cfg .secrets .ssh .vim .vscode .zprofile .zshrc .zshrc.oh-my-zsh);
  my @home_dir_files = <$HOME/\.*>;

  my @manifest = ();
  foreach my $x (@save_dot_files) {
    my $path = "$HOME/$x";
    print "Testing $x...\n";
    push @manifest, $path if -f $path;
    push @manifest, $path if -d $path;
  }

  if (@manifest > 0) {
    create_archive("dot_files", $TS, @manifest);
  }
}

################################################################################
#
# GIT DIRS
#
################################################################################

unless ($opt_skip_git_dirs) {
  my @save_git_dirs = ($HOME, "$HOME/dev", "$HOME/dev/bits.linode.com", "$HOME/dev/git.source.akamai.com", "$HOME/dev/github.com");

  my @manifest = ();
  foreach my $x (@save_git_dirs) {
    git_check($x);
    my @subdirs = <$x/*>;
    foreach my $y (@subdirs) {
      git_check($y);
    }
  }
}

sub git_check {
  my ($path) = @_;
  my $x = "$path/.git";
  #print "GIT_CHECK: [$x]\n";
  if (-d $x) {
    my @info = git_has_local_modifications($path);
    if (@info > 0) {
      print "Warning: directory [$path] has local modifications that should be dealt with!\n";
    }
  } else {
    return 0;
  }
}

sub git_has_local_modifications {
  my ($path) = @_;
  my $cmd = "(cd $path; git status $path)";
  my $has_changes = 0;
  my $is_ahead = 0;
  my $is_behind = 0;
  my @lines = ();
  open(my $h, "-|", $cmd) or die "Could not open pipe to [$cmd]! $!\n";
  while (<$h>) {
    chomp;
    push @lines, $_;
    if (/^Changes not staged for commit/) {
      $has_changes = 1;
    } elsif (/^Your branch is ahead/) {
      $is_ahead = 1;
    } elsif (/^nothing to commit/) {
    }
  }
  if ($has_changes || $is_ahead || $is_behind) {
    return @lines;
  } else {
    return ();
  }
}

sub create_archive {
  my ($name, $ts, @manifest) = @_;
  my $dir = "$ENV{'HOME'}/backups-$ts";
  mkdir $dir unless -d $dir;
  my $archive = "$dir/$ENV{'USER'}-$ts-$name.tar.bz2";
  my $log     = "$dir/$ENV{'USER'}-$ts-$name.log";
  print "Creating archive [$archive] from " . scalar @manifest . " files/directories\n";
  system "tar jcvf $archive @manifest > $log 2>&1";
  if (-f $archive) {
    print "- Success\n";
  } else {
    print "- Failed\n";
    print "- Log file: $log\n";
  }
}
