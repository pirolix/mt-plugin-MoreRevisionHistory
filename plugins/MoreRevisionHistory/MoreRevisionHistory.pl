package MT::Plugin::Revision::OMV::MoreRevisionHistory;
# MoreRevisionHistory (C) 2012 Piroli YUKARINOMIYA (Open MagicVox.net)
# This program is distributed under the terms of the GNU Lesser General Public License, version 3.
# $Id$

use strict;
use warnings;
use MT 5.1;

use vars qw( $VENDOR $MYNAME $FULLNAME $VERSION );
$FULLNAME = join '::',
        (($VENDOR, $MYNAME) = (split /::/, __PACKAGE__)[-2, -1]);
(my $revision = '$Rev$') =~ s/\D//g;
$VERSION = 'v0.10'. ($revision ? ".$revision" : '');

use base qw( MT::Plugin );
my $plugin = __PACKAGE__->new ({
    id => $FULLNAME,
    key => $FULLNAME,
    name => $MYNAME,
    version => $VERSION,
    author_name => 'Open MagicVox.net',
    author_link => 'http://www.magicvox.net/',
    plugin_link => 'http://www.magicvox.net/archive/2012/11211141/', # Blog
    doc_link => 'http://lab.magicvox.net/trac/mt-plugins/wiki/MoreRevisionHistory', # tracWiki
    description => <<'HTMLHEREDOC',
<__trans phrase="Make a few better and editable the revision history of entry and webpage.">
HTMLHEREDOC
    l10n_class => "${FULLNAME}::L10N",
    registry => {
        callbacks => {
            'app_pre_listing_list_revision' => "${FULLNAME}::Callbacks::app_pre_listing_list_revision",
        },
        applications => {
            cms => {
                methods => {
                    'omv_save_revision' => "${FULLNAME}::Methods::omv_save_revision",
                },
                callbacks => {
                    'template_source.revision_table' => "${FULLNAME}::Callbacks::template_source_revision_table",
                },
            },
        },
    },
});
MT->add_plugin ($plugin);

sub instance { $plugin; }

1;