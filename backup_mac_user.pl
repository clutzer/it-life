#!/usr/bin/env perl
use strict;

my $HOME = $ENV{'HOME'};
my $TS   = time();

print "HOME=[$HOME]\n";

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
