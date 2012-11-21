package OMV::MoreRevisionHistory::Methods;
# MoreRevisionHistory (C) 2012 Piroli YUKARINOMIYA (Open MagicVox.net)
# This program is distributed under the terms of the GNU Lesser General Public License, version 3.
# $Id$

use strict;
use warnings;
use MT;
use MT::Util;

sub instance { MT->component((__PACKAGE__ =~ /^(\w+::\w+)/g)[0]); }



### omv_save_revision
sub omv_save_revision {
    my ($app) = @_;

    $app->send_http_header ('text/json');
    # Gathering the request params, all of which must be required.
    if ($app->validate_magic
            && defined (my $user = $app->user)
            && defined (my $blog = $app->blog)
            && defined (my $_type = $app->param ('_type'))
            && defined (my $id = $app->param ('id'))
            && defined (my $r = $app->param ('r'))
            && defined (my $column = $app->param ('column'))
            && defined (my $data = $app->param ('data'))
    ) {
        $_type =~ /^(entry|page)$/
            or return "[ result:false, message:'Illegal \"_type\" parameter' ]";
        my $class = MT->model ($_type)
            or return "[ result:false, message:'Specified model not found' ]";
        my $datasource = $class->datasource
            or return "[ result:false, message:'Datasource not found' ]";

        $user->can_edit_entry($id)
            or return "[ result:false, message:'No permissions to edit $_type' ]";

        my $rev_class = MT->model ($datasource. ':revision')
            or return "[ result:false, message:'Revision model not found' ]";
        my $rev = $rev_class->load ({
            $datasource. '_id' => $id,
            rev_number => $r,
        })  or return "[ result:false, message:'Specified revision data not found' ]";

        $rev->has_column ($column)
            or return "[ result:false, message:'Invalid \"column\" parameter' ]";
        $rev->$column ($data);
        # Automatically not updated ?
        my @ts = MT::Util::offset_time_list (time, $blog->id);
        my $ts = sprintf '%04d%02d%02d%02d%02d%02d',
                $ts[5]+1900, $ts[4]+1, @ts[3,2,1,0];
        $rev->modified_on ($ts);
        $rev->modified_by ($user->id);
        $rev->update
            or return "[ result:false, message:'Revision save failed' ]";

        return "[ result:true, message:'$column has been modified successfully' ]";
    }
    return "[ result:false, message:'Illegal parameters' ]";
}

1;