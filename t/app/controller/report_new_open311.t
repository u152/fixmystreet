use FixMyStreet::TestMech;
use FixMyStreet::App;
use Web::Scraper;

# disable info logs for this test run
FixMyStreet::App->log->disable('info');
END { FixMyStreet::App->log->enable('info'); }

my $mech = FixMyStreet::TestMech->new;

my $body = $mech->create_body_ok(2245, 'Wiltshire Council');
$body->update({
    endpoint => 'http://example.com/open311',
    jurisdiction => 'mySociety',
    api_key => 'apikey',
});

# Let's make some contacts to send things to!
my $contact1 = $mech->create_contact_ok(
    body_id => $body->id, # Edinburgh
    category => 'Street lighting',
    email => '100',
    extra => [ { description => 'Lamppost number', code => 'number', required => 'True' },
               { description => 'Lamppost type', code => 'type', required => 'False', values =>
                   { value => [ { name => ['Gas'], key => ['old'] }, { name => [ 'Yellow' ], key => [ 'modern' ] } ] }
               }
             ],
);
my $contact1b = $mech->create_contact_ok(
    body_id => $body->id, # Edinburgh
    category => 'Moon lighting',
    email => '100b',
    extra => [ { description => 'Moon type', code => 'type', required => 'False', values =>
                   [ { name => 'Full', key => 'full' }, { name => 'New', key => 'new' } ] }
             ],
);
my $contact2 = $mech->create_contact_ok(
    body_id => $body->id, # Edinburgh
    category => 'Graffiti Removal',
    email => '101',
);
$mech->create_contact_ok(
    body_id => $body->id, # Edinburgh
    category => 'Ball lighting',
    email => '102',
    extra => { _fields => [
        { description => 'Size', code => 'size', required => 'True', automated => '' },
        { description => 'Speed', code => 'speed', required => 'True', automated => 'server_set' },
        { description => 'Colour', code => 'colour', required => 'True', automated => 'hidden_field' },
    ] },
);

# test that the various bit of form get filled in and errors correctly
# generated.
my $empty_form = {
    title         => '',
    detail        => '',
    photo1        => '',
    photo2        => '',
    photo3        => '',
    name          => '',
    may_show_name => '1',
    username      => '',
    email         => '',
    phone         => '',
    category      => '',
    password_sign_in => '',
    password_register => '',
    remember_me => undef,
};
foreach my $test (
    {
        msg    => 'all fields empty',
        pc     => 'EH99 1SP',
        fields => {
            %$empty_form,
            category => 'Street lighting',
        },
        changes => {
            number => '',
            type   => '',
        },
        errors  => [
            'This information is required',
            'Please enter a subject',
            'Please enter some details',
            'Please enter your email',
            'Please enter your name',
        ],
        submit_with => {
            title => 'test',
            detail => 'test detail',
            name => 'Test User',
            username => 'testopen311@example.com',
            category => 'Street lighting',
            number => 27,
            type => 'old',
        },
        extra => [
            {
                name => 'number',
                value => 27,
                description => 'Lamppost number',
            },
            {
                name => 'type',
                value => 'old',
                description => 'Lamppost type',
            }
        ]
    },
    {
        msg    => 'automated things',
        pc     => 'EH99 1SP',
        fields => {
            %$empty_form,
            category => 'Ball lighting',
        },
        changes => {
            size => '',
        },
        hidden => [ 'colour' ],
        errors  => [
            'This information is required',
            'Please enter a subject',
            'Please enter some details',
            'Please enter your email',
            'Please enter your name',
        ],
        submit_with => {
            title => 'test',
            detail => 'test detail',
            name => 'Test User',
            username => 'testopen311@example.com',
            size => 'big',
            colour => 'red',
        },
        extra => [
            {
                name => 'size',
                value => 'big',
                description => 'Size',
            },
            {
                name => 'colour',
                value => 'red',
                description => 'Colour',
            }
        ]
    },
  )
{
    subtest "check form errors where $test->{msg}" => sub {
        $mech->log_out_ok;
        $mech->clear_emails_ok;

        # check that the user does not exist
        my $test_email = $test->{submit_with}->{username};
        my $user = FixMyStreet::App->model('DB::User')->find( { email => $test_email } );
        if ( $user ) {
            $user->problems->delete;
            $user->comments->delete;
            $user->delete;
        }

        $mech->get_ok('/around');

        # submit initial pc form
        FixMyStreet::override_config {
            ALLOWED_COBRANDS => [ { 'fixmystreet' => '.' } ],
            MAPIT_URL => 'http://mapit.uk/',
        }, sub {
            $mech->submit_form_ok( { with_fields => { pc => $test->{pc} } },
                "submit location" );
            is_deeply $mech->page_errors, [], "no errors for pc '$test->{pc}'";

            # click through to the report page
            $mech->follow_link_ok( { text_regex => qr/skip this step/i, },
                "follow 'skip this step' link" );

            # submit the main form
            $mech->submit_form_ok( { with_fields => $test->{fields} },
                "submit form" );
        };

        # check that we got the errors expected
        is_deeply $mech->page_errors, $test->{errors}, "check errors";

        # check that fields have changed as expected
        my $new_values = {
            %{ $test->{fields} },     # values added to form
            %{ $test->{changes} },    # changes we expect
        };
        is_deeply $mech->visible_form_values, $new_values,
          "values correctly changed";
        if ($test->{hidden}) {
            my %hidden_fields = map { $_->name => 1 } grep { $_->type eq 'hidden' } ($mech->forms)[0]->inputs;
            foreach (@{$test->{hidden}}) {
                is $hidden_fields{$_}, 1;
            }
        }

        if ( $test->{fields}->{category} eq 'Street lighting' ) {
            my $result = scraper {
                process 'select#form_type option', 'option[]' => '@value';
            }
            ->scrape( $mech->response );

            is_deeply $result->{option}, [ "", qw/old modern/], 'displayed streetlight type select';
        }

        $new_values = {
            %{ $test->{fields} },
            %{ $test->{submit_with} },
        };
        FixMyStreet::override_config {
            ALLOWED_COBRANDS => [ { 'fixmystreet' => '.' } ],
            MAPIT_URL => 'http://mapit.uk/',
        }, sub {
            $mech->submit_form_ok( { with_fields => $new_values } );
        };

        $user = FixMyStreet::App->model('DB::User')->find( { email => $test_email } );
        ok $user, 'created user';
        my $prob = $user->problems->first;
        ok $prob, 'problem created';

        is_deeply $prob->get_extra_fields, $test->{extra}, 'extra open311 data added to problem';

        $user->problems->delete;
        $user->delete;
    };
}

done_testing();
