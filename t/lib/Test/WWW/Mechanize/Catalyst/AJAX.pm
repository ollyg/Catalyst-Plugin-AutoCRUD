package Test::WWW::Mechanize::Catalyst::AJAX;

use base 'Test::WWW::Mechanize::Catalyst';
use Test::More;
use JSON;

sub ajax_ok {
    my ($self, $path, $args, $expected, $message, $dump) = @_;
    $message = ($message ? " - $message" : '');

    my $post = $self->post_ok( $path, $args, 'POST'. $message );
    my $ct = is( $self->ct, 'application/json', 'AJAX content type'. $message );
    my $response = JSON::from_json( $self->content );
    shift @{ $response->{rows} } if $path =~ m#/list$#;

    if ($dump) {
        use Data::Dumper; # yeah, I know
        print STDERR Dumper $response;
        return ($post && $ct);
    }

    my $id = is_deeply( $response, $expected, 'AJAX JSON data compare'. $message );

    return ($post && $ct && $id);
}

1;
__END__
