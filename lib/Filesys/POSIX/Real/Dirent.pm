package Filesys::POSIX::Real::Dirent;

use strict;
use warnings;

use Filesys::POSIX::Bits;

sub new {
    my ($class, $path, $node) = @_;

    return bless {
        'path'      => $path,
        'node'      => $node,
        'mtime'     => 0,
        'members'   => {}
    }, $class;
}

sub _update {
    my ($self, %opts) = @_;
    my $mtime = (lstat $self->{'path'})[9];

    unless ($opts{'force'}) {
        return unless $mtime > $self->{'mtime'};
    }

    opendir(my $dh, $self->{'path'}) or die $!;

    my $node = $self->{'node'};
    my $parent = $self->{'node'}->{'parent'};

    $self->{'mtime'} = $mtime;
    $self->{'members'} = {
        '.'     => $node,
        '..'    => $parent? $parent: $node,

        map {
            $_ => Filesys::POSIX::Real::Inode->new("$self->{'path'}/$_",
                'dev'       => $self->{'node'}->{'dev'},
                'parent'    => $self->{'node'}
            )
        } grep {
            $_ ne '.' && $_ ne '..'
        } readdir($dh)
    };

    closedir($dh);
}

sub get {
    my ($self, $name) = @_;
    $self->_update;

    return $self->{'members'}->{$name};
}

sub set {
    return;
}

sub exists {
    my ($self, $name) = @_;
    $self->_update;

    return exists $self->{'members'}->{$name};
}

sub delete {
    my ($self, $name) = @_;
    my $member = $self->{'members'}->{$name} or return;
    my $path = "$self->{'path'}/$name";

    die('Invalid directory entry name') if $name =~ /\//;

    if ($member->{'mode'} & $S_IFDIR) {
        rmdir($path) or die $!;
    } else {
        unlink($path) or die $!;
    }

    $self->_update('force' => 1);
}

sub list {
    my ($self, $name) = @_;
    $self->_update;

    return keys %{$self->{'members'}};
}

sub count {
    my ($self) = @_;
    $self->_update;

    return scalar keys %{$self->{'members'}};
}

1;
