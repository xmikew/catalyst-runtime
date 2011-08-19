package TestCustomContainer;
use Moose;
use namespace::autoclean;
use Test::More;

has app_name => (
    is => 'ro',
    isa => 'Str',
    default => 'TestAppCustomContainer',
);

has container_class => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

has sugar => (
    is => 'ro',
    isa => 'Int',
);

# Reason for this class:
# I wanted have a set of tests that would test both the sugar version of the
# container, as the sugar-less. I figured I shouldn't just copy and paste
# the tests. So after struggling for hours to find a way to test twice
# against the same TestApp using only one file, I decided to break it
# into a separate class (this one), and call it at
#           -  live_container_custom_container_sugar.t and
#           -  live_container_custom_container_nosugar.t
# setting only the sugar attribute.

sub BUILD {
    my $self = shift;
    my $app  = $self->app_name;

    $ENV{TEST_APP_CURRENT_CONTAINER} = $self->container_class;

    require Catalyst::Test;
    Catalyst::Test->import($app);

    is($app->config->{container_class}, $self->container_class, 'config is set properly');
    isa_ok($app->container, $self->container_class, 'and container isa our container class');

    {
        ok(my ($res, $c) = ctx_request('/'), 'request');
        ok($res->is_success, 'request 2xx');
        is($res->content, 'foo', 'content is expected');

        ok(my $model = $c->container->get_sub_container('model')->resolve(service => 'RequestLifeCycle', parameters => { ctx => $c, accept_context_args => [$c] } ), 'fetching RequestLifeCycle');
        isa_ok($model, 'TestAppCustomContainer::Model::RequestLifeCycle');

        ok(my $model2 = $c->model('RequestLifeCycle'), 'fetching RequestLifeCycle again');
        is($model, $model2, 'object is not recreated during the same request');
    }

    done_testing;
}

sub _build_container_class {
    my $self = shift;

    my $sugar = $self->sugar ? '' : 'No';

    return $self->app_name . "::${sugar}SugarContainer";
}

__PACKAGE__->meta->make_immutable;

1;