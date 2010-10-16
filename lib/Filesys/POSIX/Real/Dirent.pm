package Filesys::POSIX::Real::Dirent;

use strict;
use warnings;

use Filesys::POSIX::Real::Inode;

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
    my ($self) = @_;
    my $mtime = (stat $self->{'path'})[9];

    return unless $mtime > $self->{'mtime'};

    opendir(my $dh, $self->{'path'}) or die $!;

    $self->{'mtime'} = $mtime;
    $self->{'members'} = {
        map {
            $_ => Filesys::POSIX::Real::Inode->new("$self->{'path'}/$_",
                'dev'       => $self->{'node'}->{'dev'},
                'parent'    => $self->{'node'}
            )
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
    return;
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
