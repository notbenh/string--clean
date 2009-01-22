package String::Clean::Object;
use Moose;
use YAML;
require String::Clean;

sub replace {
   my $self = shift;
   String::Clean::replace(@_);
}
sub replace_word {
   my $self = shift;
   String::Clean::replace_word(@_);
}
sub strip {
   my $self = shift;
   String::Clean::strip(@_);
}
sub strip_word {
   my $self = shift;
   String::Clean::strip_word(@_);
}
sub clean_by_yaml {
   my $self = shift;
   String::Clean::clean_by_yaml(@_);
}

#---------------------------------------------------------------------------
#  Helpers
#---------------------------------------------------------------------------
# possible use MEMOIZE
sub _yaml_parse {}


__END__



our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub _defaults {
   return (
      word_boundary => '\b',  # STR
      opt           => '',    # STR
      escape        => 1,     # BOOL
      word          => 0,     # BOOL
   );
}

#---------------------------------------------------------------------------
#  Replace
#---------------------------------------------------------------------------
sub replace {
   my ( $hash, $string, $opts ) = @_;

   assert_hashref($hash);
   assert_defined($string);
   my $o = { _defaults(), %$opts };

   while ( my ($search, $replace) = each %$hash ) {
      $search = _manage_search($search, $o);
      if ($opts->{word}) {
         $string =~ s/$search/$1$replace$2/gx;
      } else {
         $string =~ s/$search/$replace/gx;
      }
   }
   return $string;
}

sub replace_word {
   my ( $hash, $string, $opts ) = @_;
   assert_hashref($hash);
   assert_defined($string);
   my $o = { %$opts, word => 1 };
   return replace($hash, $string, $o);
}


#---------------------------------------------------------------------------
#  Strip
#---------------------------------------------------------------------------
sub strip {
   my ( $list, $string , $opts) = @_;

   assert_listref($list);
   assert_defined($string);
   my $o = { _defaults(), %$opts };
   foreach my $search (@$list) {
      $search = _manage_search($search, $o);
      $string =~ s/$search//g;
   }
   return $string;
}

sub strip_word {
   my ( $list, $string, $opts ) = @_;
   assert_listref($list);
   assert_defined($string);
   my $o = { %$opts, word => 1 };
   return strip($list, $string, $o);
}


#---------------------------------------------------------------------------
#  YAML
#---------------------------------------------------------------------------
sub clean_by_yaml {
   use YAML qw{Load LoadFile};
   my ( $yaml, $string, $opts) = @_;
   assert_nonref($yaml);
   assert_defined($string);
   my $o = { _defaults(), %$opts };

   my $rel = sub{ use File::Fu;
                  my ($file) = @_;
                  return ( File::Fu->program_dir + $file )->stringify;
                };

   my @docs = ( -r $yaml )         ? LoadFile($yaml) 
            : ( -r $rel->($yaml) ) ? LoadFile( $rel->($yaml) )
            :                        Load($yaml);

   foreach my $doc (@docs) {
      if ( ref($doc) eq 'ARRAY' ) {
         $string = strip( $doc, $string, $o);
      }
      elsif ( ref($doc) eq 'HASH' ) {
         $string = replace( $doc, $string , $o);
      }
      else {
         warn '!!! FAILURE !!! unknown type of data struct for $data. Skipping and moving on.';
      }
   }
   return $string;
}

#---------------------------------------------------------------------------
#  Helpers
#---------------------------------------------------------------------------
sub _manage_search {
   my ($search, $opts) = @_;

   $search = quotemeta($search) if $opts->{escape} ;
   $search = sprintf q{(?-%s)%s}, $opts->{opt}, $search 
      if defined $opts->{opt} && length $opts->{opt};
   $search  = sprintf qr{(\^|%s)%s(%s|$)}, $opts->{word_boundary}, $search, $opts->{word_boundary}
      if $opts->{word} ;
   return $search;
}























1;

__END__
use Moose;
use Carp::Assert::More;

with qw{
   MooseX::MutatorAttributes
};

=head1 NAME

String::Clean - use data objects to clean strings

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

The goal of this module is to assist in the drudgery of string cleaning by 
allowing data objects to define what and how to clean. 

=head2 EXAMPLES

   use String::Clean;

   my $clean = String::Clean->new();

   $clean->replace( { this => 'that', is => 'was' } , 'this is a test' ); 
      # returns 'that was a test'
   
   # see the tests for more examples 

=head1 THE OPTIONS HASH

Each function can take an optonal hash that will change it's behaviour. This 
hash can be passed to new and will change the defaults, or you can pass to each
call as needed. 

   opt: 
         Any regex options that you want to pass, ie {opt => 'i'} will allow 
         for case insensitive manipulation.
   replace : 
         If the value is set to 'word' then the replace function will look for 
         words instead of just a collection of charicters. 
         example: 

            replace( { is => 'was' },
                     'this is a test',
                   ); 

            returns 'thwas was a test', where 

            replace( { is => 'was' },
                     'this is a test',
                     { replace => 'word' },
                   ); 

            will return 'this was a test' 

   strip :
         Just like replace, if the value is set to 'word' then strip will look
         for words instead of just a collection of charicters. 

   word_ boundary :
         Hook to change what String::Clean will use as the word boundry, by 
         default it will use '\b'. Mainly this would allow String::Clean to 
         deal with strings like 'this,is,a,test'.

   escape :
         If this is set to 'no' then String::Clean will not try to escape any 
         of the things that you've asked it to look for.  

You can also override options at the function level again, but this happens as
merged hash, for example:

   my $clean = String::Clean->new({replace => 'word', opt => 'i'});
   $clean->strip( [qw{a}], 'an Array', {replace =>'non-word'} );
   #returns 'n rray' because opt => 'i' was pulled in from the options at new.
 

=head1 CORE FUNCTIONS

=head2 new

The only thing exciting here is that you can pass the same options hash at 
construction, and this will cascade down to each function call. 

=cut

#---------------------------------------------------------------------------
#  Options
#---------------------------------------------------------------------------
use constant SC_ATTR => qw{ opt escape word word_boundary };

has opt => (
   is => 'rw',
   isa => 'Str',
   default => '',
   #default => '-i',
);

has escape => (
   is => 'rw',
   isa => 'Bool',
   default => 1,
);

#  !!!!!!!!!!! CRAP !!!!!!!!!!!!
#has [qw{replace_word strip_word}] => (
has word => (
   is => 'rw',
   isa => 'Bool',
   default => 0,
);

has word_boundary => (
   is => 'rw',
   isa => 'Str',
   default => '\b',
);

#---------------------------------------------------------------------------
#  REPLACE
#---------------------------------------------------------------------------
=head2 replace

Takes a hash where the key is what to look for and the value is what to replace
the key with.

   replace( $hash, $string, $opts );

=cut

sub replace {
   my ( $self, $hash, $string , $opt) = @_;
   assert_hashref($hash);
   assert_defined($string);
   $self->set(%$opt) if defined $opt && ref($opt) eq 'HASH';

   while ( my ($search, $replace) = each %$hash ) {
      $search = $self->_manage_search($search);
      if ($self->word) {
         $string =~ s/$search/$1$replace$2/gx;
      } else {
         $string =~ s/$search/$replace/gx;
      }
   }
   return $string;
}

=head2 replace_word

A shortcut that does the same thing as passing {replace => 'word'} to replace.

   replace_word( $hash, $string, $opts ); 

=cut

sub replace_word {
   my ( $self, $hash, $string , $opt) = @_;
   my $inital_state = $self->word;
   $self->word(1);
   $string = $self->replace($hash, $string, $opt);
   $self->word($inital_state);
   return $string;
}


#---------------------------------------------------------------------------
#  STRIP
#---------------------------------------------------------------------------

=head2 strip

Takes an arrayref of items to completely remove from the string.

   strip( $list, $sring, $opt);

=cut

sub strip {
   my ( $self, $list, $string , $opt) = @_;

   assert_listref($list);
   assert_defined($string);
   foreach my $search (@$list) {
      $search = $self->_manage_search($search);
      $string =~ s/$search//g;
   }
   return $string;
}

=head2 strip_word

A shortcut that does the same thing as passing {strip => 'word'} to strip.

   strip_word( $list, $string, $opt);

=cut

sub strip_word {
   my ( $self, $hash, $string , $opt) = @_;
   my $inital_state = $self->word;
   $self->word(1);
   $string = $self->replace($hash, $string, $opt);
   $self->word($inital_state);
   return $string;
}

#---------------------------------------------------------------------------
#  CLEAN BY YAML
#---------------------------------------------------------------------------

=head1 WRAPPING THINGS UP AND USING YAML

=head2 clean_by_yaml

Because we have to basic functions that take two seperate data types... why 
not wrap those up, enter YAML. 

   clean_by_yaml( $yaml, $string, $opt );

But how do we do that? Heres an example:

=head3 OLD CODE

   $string = 'this is still just a example for the YAML stuff';
   $string =~ s/this/that/;
   $string =~ s/is/was/;
   $string =~ s/\ba\b/an/;
   $string =~ s/still//;
   $string =~ s/for/to explain/;
   $string =~ s/\s\s/ /g;
   # 'that was just an example to explain the YAML stuff'

=head3 NEW CODE

   $string = 'this is still just a example for the YAML stuff';
   $yaml = q{
   ---
   this : that
   is   : was
   a    : an
   ---
   - still
   ---
   for : to explain
   '  ': ' '
   };
   $string = $clean->clean_by_yaml( $yaml, $string, { replace => 'word' } );
   # 'that was just an example to explain the YAML stuff'

=head3 ISSUES TO WATCH FOR:

=over

=item * Order matters:

As you can see in the example we have 3 seperate YAML docs, this allows for
replaces to be doene in a specific sequence, if that is needed. Here in this
example is would not have mattered that much, here's a better example:

   #swap all instances of 'ctrl' and 'alt' 
   $yaml = q{
   ---
   ctrl : __was_ctrl__
   ---
   alt  : ctrl
   ---
   __was_ctrl__ : alt
   };

=item * Options are global to the YAML doc :
   
If you need to have seperate options applied to seperate sets then they
will have to happen as seprate calls.

=back 

=cut

sub clean_by_yaml {
   use YAML;
   my ( $self, $yaml, $string, $opt) = @_;
   assert_defined($yaml);
   assert_defined($string);
   $opt = $self->_check_for_opt($opt);
   my @data = Load($yaml);
   foreach my $doc (@data) {
      if ( ref($doc) eq 'ARRAY' ) {
         $string = $self->strip( $doc, $string, $opt);
      }
      elsif ( ref($doc) eq 'HASH' ) {
         $string = $self->replace( $doc, $string , $opt);
      }
      else {
         warn '!!! FAILURE !!! unknown type of data struct for $data. Skipping and moveing on.';
      }
   }
   return $string;
}

#---------------------------------------------------------------------------
#  Helper function that do not get exported and should only be run localy
#---------------------------------------------------------------------------
sub _manage_search {
   my ($self, $search) = @_;

   $search = quotemeta($search) if $self->escape ;
   $search = sprintf q{(?-%s)%s}, $self->opt, $search 
      if length $self->opt;
   $search  = sprintf qr{(\^|%s)%s(%s|$)}, $self->word_boundary, $search, $self->word_boundary
      if $self->word ;

   return $search;
}

sub _build_opt {
   my ($self, $opt) = @_;
   my $default = { map{ $_ => $self->$_} SC_ATTR };
}

sub _check_for_opt {
   my ($self, $opt) = @_;
   if (! defined($opt) 
       && defined($self->{opt})
   ) {
      return $self->{opt};
   }
   elsif ( defined($opt) 
       && defined($self->{opt})
   ) {
      return { %{$self->{opt}}, %$opt };
   }
   else {
      return $opt;
   }
}


=head1 AUTHOR

ben hengst, C<< <notbenh at CPAN.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-string-clean at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Clean>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::Clean


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-Clean>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/String-Clean>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/String-Clean>

=item * Search CPAN

L<http://search.cpan.org/dist/String-Clean>

=back


=head1 ACKNOWLEDGEMENTS
Lindsey Kuper and Jeff Griffin for giving me a reason to cook up this scheme.


=head1 COPYRIGHT & LICENSE

Copyright 2007 ben hengst, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of String::Clean