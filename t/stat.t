use strict;
use warnings;

use Filesys::POSIX ();
use Filesys::POSIX::Mem ();
use Filesys::POSIX::Bits;

use Test::More ('tests' => 4);

my $fs = Filesys::POSIX->new(Filesys::POSIX::Mem->new);

my $fd = $fs->open('foo', $O_CREAT | $O_WRONLY);
my $file_inode = $fs->fstat($fd);

ok(ref($file_inode) =~ /::Inode$/, 'Filesys::POSIX->fstat() returns an inode on an open file descriptor');

$fs->symlink('foo', 'bar');
my $symlink_inode = $fs->lstat('bar');

ok($fs->stat('foo') eq $file_inode, 'Filesys::POSIX->stat() on name of open file returns same inode as fstat()');
ok($fs->stat('bar') eq $file_inode, 'Filesys::POSIX->stat() on symlink to open file returns same inode as fstat()');
ok($fs->lstat('bar')->link,         'Filesys::POSIX->lstat() on symlink to open file returns symlink inode');
