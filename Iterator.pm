package File::Iterator;

use 5.005;
use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;

@ISA          = qw( Exporter );
%EXPORT_TAGS  = ( 'all' => [ qw() ] );
@EXPORT_OK    = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT       = qw( );
$VERSION      = '0.06';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{ARGS} = {
		DIR		=> '.',
		RECURSE	=> 1,
		FILTER	=> '',
		@_
	};
	
	if ($self->{ARGS}{FILTER}) {
		# convert file filter string into a regexp, e.g. "*.txt; *.cf" becomes  .*\.txt|.*\.cf
		$self->{ARGS}{FILTER} =~ s/\./\\./g;
		$self->{ARGS}{FILTER} =~ s/\*/.*/g;
		$self->{ARGS}{FILTER} =~ s/[,;] */|/g;
	}
	
	$self->{FILES} = [];
	$self->{CURRENT} = -1;
	bless ($self, $class);
	$self->_getFiles( $self->{ARGS}{DIR} );
	return $self;
}

sub _getFiles {
	my $self = shift;
	my $dir = shift;
	my $file;
	local *DIR;
	
	if (opendir(DIR, $dir)) {
		while (defined ($file = readdir(DIR))) {
			next if $file =~ /^\.\.?$/;
			if ( -d "$dir/$file" && $self->{ARGS}{RECURSE} ) {
				$self->_getFiles("$dir/$file");
			}
			elsif ( -f "$dir/$file" ) {
				if ( $self->{ARGS}{FILTER} && $file !~ /^$self->{ARGS}{FILTER}$/o ) {
					next;
				}
				else {
					push @{$self->{FILES}}, "$dir/$file";
				}
			}
		}
		closedir DIR or carp "On closing $dir: $!";
	}
	else {
		carp "On opening $dir: $!";
	}
}

sub hasNext {
	my $self = shift;
	return $self->{CURRENT} < scalar @{$self->{FILES}} - 1;
}

sub next {
	my $self = shift;
	return $self->{FILES}[++$self->{CURRENT}];
}

sub reset {
	my $self = shift;
	$self->{CURRENT} = -1;
}

1;

__END__
=head1 NAME

File::Iterator - an object-oriented Perl module for iterating across
files in a directory tree.

=head1 SYNOPSIS

  use File::Iterator;

  $it = new File::Iterator(
    DIR     => '/etc',
    RECURSE => 1,
    FILTER  => '*.cf',
  );

  while ($it->hasNext()) {
    $file = $it->next();
    # do stuff with $file
  }

=head1 INTRODUCTION

File::Iterator wraps a simple iteration interface around the files in
a directory or directory tree. It builds a list of filenames, and
maintains a cursor that points to one particular filename. The user can 
work through the filenames sequentially by doing stuff with the filename
that the cursor points to and then advancing the cursor to the next filename
in the list.

=head1 CONSTRUCTOR

=over 2

=item new( [ DIR => '$somedir' ] [, RECURSE => 0 ] [, FILTER => '*.ext; filename.*' ] )

The constructor for a File::Iterator object. The root directory for
the iteration is specified as shown. If DIR is not specified, the
current directory is used.

By default, File::Iterator works recursively, and will therefore list
all files in the root directory and all its subdirectories. To use
File::Iterator non-recursively, set the RECURSE option to 0.

You can also optionally specify a filename filter using the FILTER
option. Separate multiple filters with ; or , as shown.

=back

=head1 METHODS

=over 2

=item hasNext()

Evaluates to true while there are more files to process.

=item next()

Returns the name of the next file (including the path) and advances
the cursor to the next filename. Note that because next() advances the
cursor, the following code will produce erroneous results, because the 
two calls to next() return different values:

	while ($it->hasNext()) {
		push @textfiles, $it->next() if -T $it->next();
	}

What you wanted to write was:
	
	while ($it->hasNext()) {
		$file = $it->next();
		push @textfiles, $file if -T $file;
	}

=item reset()

Resets the iterator so that the next call to next() returns the first
file in the list.

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Marius Feraru for reminding me to use /o 

=head1 AUTHOR

Copyright 2002 Simon Whitaker E<lt>swhitaker@cpan.orgE<gt>

=cut
