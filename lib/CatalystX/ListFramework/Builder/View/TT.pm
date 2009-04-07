package CatalystX::ListFramework::Builder::View::TT;

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::View::TT';
use File::Basename;
use MRO::Compat;

# the templates are squirreled away in ../templates
(my $pkg_path = __PACKAGE__) =~ s{::}{/}g;
my (undef, $directory, undef) = fileparse(
    $INC{ $pkg_path .'.pm' }
);

__PACKAGE__->config(
    INCLUDE_PATH => "$directory../templates",
    CATALYST_VAR => 'c',
    WRAPPER => 'wrapper.tt',
);

# override to push a template var giving easy access to our plugin conf
sub template_vars {
    my ($self, $c) = (shift, $_[0]);

    my @vars = $self->next::method(@_);
    return @vars, ( cpac => $c->config->{'Catalyst::Plugin::AutoCRUD'} );
}

sub process {
    my ($self, $c) = (shift, $_[0]);

    # this is done to cope with users of RenderView who have not set
    # default_view, meaning $c->view ends here by mistake

    if (!exists $c->{stash}->{current_view}) {
        my @views = grep {$_ !~ m/^LFB::/} $c->views;
        scalar @views || die "View::LFB::TT called, but not by LFB.\n";
        $c->forward( $c->view( $views[0] ) );
    }
    else {
        return $self->next::method(@_);
    }
}

1;
__END__
