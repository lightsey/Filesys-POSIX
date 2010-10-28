use strict;
use warnings;

use Filesys::POSIX;
use Filesys::POSIX::Mem;
use Filesys::POSIX::Bits;

use Test::More ('tests' => 24);

my $mounts = {
    '/'             => Filesys::POSIX::Mem->new,
    '/mnt/mem'      => Filesys::POSIX::Mem->new,
    '/mnt/mem/tmp'  => Filesys::POSIX::Mem->new
};

my $fs = Filesys::POSIX->new($mounts->{'/'});

$fs->mkpath('/mnt/mem/hidden');

foreach (grep { $_ ne '/' } sort keys %$mounts) {
    eval {
        $fs->mkpath($_);
    };

    ok(!$@, "Able to create mount point $_");

    eval {
        $fs->mount($mounts->{$_}, $_,
            'noatime' => 1
        );
    };

    ok(!$@, "Able to mount $mounts->{$_} to $_");
}

eval {
    $fs->stat('/mnt/mem/hidden');
};

ok($@ =~ /^No such file or directory/, "Mounting /mnt/mem sweeps /mnt/mem/hidden under the rug");

{
    my $expected    = $mounts->{'/'};
    my $result      = $fs->{'root'}->{'dev'};

    ok($result eq $expected, "Filesystem root device lists $result");
}

foreach (sort keys %$mounts) {
    my $inode = $fs->stat($_);

    my $expected    = $mounts->{$_};
    my $result      = $inode->{'dev'};

    ok($result eq $expected, "$_ inode lists $result as device");

    my $mount = eval {
        $fs->statfs($_);
    };

    my $fd = $fs->open("$_/emptyfile", $O_CREAT);

    ok(!$@, "Filesys::POSIX->statfs('$_/') returns mount information");
    ok($mount->{'dev'} eq $expected, "Mount object for $_ lists expected device");
    ok($fs->fstatfs($fd) eq $mount, "Filesys::POSIX->fstatfs() on open file descriptor returns expected mount object");

    $fs->close($fd);
}

{
    $fs->chdir('/mnt/mem/tmp');
    ok($fs->getcwd eq '/mnt/mem/tmp', "Filesys::POSIX->getcwd() reports /mnt/mem/tmp after a chdir()");

    $fs->chdir('..');
    ok($fs->getcwd eq '/mnt/mem', "Filesys::POSIX->getcwd() reports /mnt/mem after a chdir('..')");

    $fs->chdir('..');
    ok($fs->getcwd eq '/mnt', "Filesys::POSIX->getcwd() reports /mnt after a chdir('..')");

    $fs->chdir('..');
    ok($fs->getcwd eq '/', "Filesys::POSIX->getcwd() reports / after a chdir('..')");
}

{
    eval {
        $fs->unmount('/mnt/mem');
    };

    ok($@ =~ /^Device or resource busy/, "Filesys::POSIX->unmount() prevents unmounting busy filesystem /mnt/mem");
}

{
    $fs->unmount('/mnt/mem/tmp');
    $fs->unmount('/mnt/mem');

    eval {
        $fs->stat('/mnt/mem/tmp');
    };

    ok($@ =~ /^No such file or directory/, "/mnt/mem/tmp can no longer be accessed after unmounting /mnt/mem");
}