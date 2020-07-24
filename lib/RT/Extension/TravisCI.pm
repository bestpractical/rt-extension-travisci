use strict;
package RT::Extension::TravisCI;

our $VERSION = '0.01';

=head1 NAME

RT-Extension-TravisCI - Pull status of latest build from TravisCI

=cut

require RT::Config;
use LWP::UserAgent ();
use URI::Escape;
use JSON;

$RT::Config::META{TravisCI} = {
    Type => 'HASH',
};

RT->AddStyleSheets("travisci.css");

sub getconf
{
    my $thing = shift;
    return RT->Config->Get('TravisCI')->{$thing};
}

sub parse_subject_for_project_and_branch
{
    my $subject = shift;
    if ($subject =~ /^([A-Za-z_.-]+)[\/ ](.+)/) {
        RT->Logger->debug(
            "Extracted project '$1' and branch '$2' from ticket subject '$subject'");
        return ($1, $2);
    } else {
        my $proj = getconf('DefaultProject') // 'rt';
        RT->Logger->debug("Using ticket subject as branch '$subject' in project $proj");
        return ($proj, $subject);
    }
}

sub pretty_state {
    my $state = shift;
    return "Passed" if ($state eq 'passed');
    return "Failed" if ($state eq 'failed');
    return "Errored" if ($state eq 'errored');
    return $state;
}

sub get_status
{
    my $proj = shift;
    my $branch = shift;

    my $ua = LWP::UserAgent->new();

    my $url = getconf('APIURL') . '/repo/' . getconf('SlugPrefix') . uri_escape($proj) . '/branch/' . uri_escape($branch);
    my $response = $ua->get($url,
                            'Travis-API-Version' => getconf('APIVersion'),
                            'Authorization' => 'token ' . getconf('AuthToken'),
        );

    if (!$response->is_success) {
        return { success => 0, error => $response->status_line };
    }

    my $result;
    eval {
        $result = decode_json($response->decoded_content);
    };
    if ($@) {
        return { success => 0, error => 'Could not parse result as JSON' };
    }

    return { success => 1, result => $result };
}

1;

__END__

=head1 DESCRIPTION

This extension provides a portlet showing the TravisCI build results
for the latest build on a branch.

=head1 RT VERSION

Works with RT 4.4, 5.0

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::TravisCI');

=item Edit your F</opt/rt4/local/plugins/RT-Extension-TravisCI/etc/TravisCI_Config.pm>

The settings you are most likely to want to change are F<SlugPrefix>, which
should be your organization's identifier follwed by an escaped slash: %2F;
DefaultProject, Queues and AuthToken.

You will need to generate an authentication token as documented in
https://medium.com/@JoshuaTheMiller/retrieving-your-travis-ci-api-access-token-bc706b2b625a

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-TravisCI@rt.cpan.org">bug-RT-Extension-TravisCI@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-TravisCI">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-TravisCI@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-TravisCI

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
