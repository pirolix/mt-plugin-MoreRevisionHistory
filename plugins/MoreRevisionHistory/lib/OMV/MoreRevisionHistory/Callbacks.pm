package OMV::MoreRevisionHistory::Callbacks;
# MoreRevisionHistory (C) 2012 Piroli YUKARINOMIYA (Open MagicVox.net)
# This program is distributed under the terms of the GNU Lesser General Public License, version 3.
# $Id$

use strict;
use warnings;
use MT;

sub instance { MT->component((__PACKAGE__ =~ /^(\w+::\w+)/g)[0]); }



### Modufy and Add into the each row data
sub app_pre_listing_list_revision {
    my ($cb, $app, $terms, $args, $param, $hasher) = @_;

    # Works when only _type is entry or page
    my $_type = $app->param ('_type');
    return if $_type !~ /^(entry|page)$/;

    # Override the hasher
    my $org_hasher = $$hasher;
    $$hasher = sub {
        my ($rev, $row) = @_;
        $org_hasher->($rev, $row);

        $row->{revision_changed} = join ', ', map {
            MT->translate (MT->model($_type)->column_defs()->{$_}{label} || $_);
        } split ',', $rev->changed;
    };

    # Fill any other parameters
    $param->{object_id} = $terms->{entry_id};
}

### Modify the revision table
sub template_source_revision_table {
    my ($cb, $app, $tmpl) = @_;
    my ($old, $new);

    my $_type = $app->param ('_type');
    return if $_type !~ /^(entry|page)$/;

    ### Table header
    chomp ($old = <<'MTMLHEREDOC');
<th class="col head note primary"><span class="col-label"><__trans phrase="Note">
MTMLHEREDOC
    chomp ($new = &instance->translate_templatized (<<'MTMLHEREDOC'));
 (<__trans phrase="Modified Columns">)
MTMLHEREDOC
    $$tmpl =~ s/(\Q$old\E)/$1$new/;

    ### Revision number
    chomp ($old = <<'MTMLHEREDOC');
<mt:date ts="$created_on" format="%Y-%m-%d %H:%M:%S"></a></span>
MTMLHEREDOC
    chomp ($new = &instance->translate_templatized (<<'MTMLHEREDOC'));
<br /><span class="revision-number" title="<__trans phrase="Revision Number">">@<mt:var rev_number></span>
MTMLHEREDOC
    $$tmpl =~ s/(\Q$old\E)/$1$new/;

    ### Add buttons for editing revision description
    chomp ($old = <<'MTMLHEREDOC');
<span class="revision-note"><mt:var name="description" escape="html"></span>
MTMLHEREDOC
    chomp ($new = &instance->translate_templatized (<<'MTMLHEREDOC'));
<span class="action-icon clickable edit icon-draft icon16" title="<__trans phrase="Edit Note">"><__trans phrase="Edit Note"></span>
<input class="hidden input-description" type="text" name="rev-num-<mt:var rev_number>" value="<mt:var name="description" escape="html">" />
<span class="hidden action-icon clickable submit icon-success icon16" title="<__trans phrase="Save Changes">"><__trans phrase="Save Changes"></span>
<span class="hidden action-icon clickable cancel icon-close icon16" title="<__trans phrase="Cancel">"><__trans phrase="Cancel"></span><br />
<span class="revision-changed">(<mt:var revision_changed>)</span>
MTMLHEREDOC
    $$tmpl =~ s/(\Q$old\E)/$1$new/;

    ### Add scripts for editing revision description
    chomp ($new = &instance->translate_templatized (<<'MTMLHEREDOC'));
<script type="text/javascript">
    // <__trans phrase="Edit Note">
    jQuery('span.action-icon.clickable.edit').click(function(){
        var text =
        jQuery(this).addClass('hidden')
            .siblings('span.revision-note').addClass('hidden').html().decodeHTML();
        jQuery(this)
            .siblings('input.input-description').val(text).removeClass('hidden')
            .siblings('span.action-icon.submit').removeClass('hidden')
            .siblings('span.action-icon.cancel').removeClass('hidden');
    });
    // <__trans phrase="Cancel">
    jQuery('span.action-icon.clickable.cancel').click(function(){
        jQuery(this).addClass('hidden')
            .siblings('input.input-description').addClass('hidden')
            .siblings('span.action-icon.submit').addClass('hidden')
            .siblings('span.action-icon.edit').removeClass('hidden')
            .siblings('span.revision-note').removeClass('hidden');
    });
    // <__trans phrase="Save Changes">
    jQuery('span.action-icon.clickable.submit').click(function(){
        var text =
        jQuery(this)
            .siblings('input.input-description').val();
        var r =
        jQuery(this)
            .siblings('span.revision-note').html(text.encodeHTML())
            .siblings('input.input-description').attr('name').replace(/\D/g,'');

        var self = this;
        var request_param = {
            __mode      : 'omv_save_revision',
            _type       : '<mt:var object_type regex_replace="/:\w+$/","">',
            blog_id     : <mt:var blog_id>,
            id          : <mt:var object_id>,
            r           : r,
            column      : 'description',
            data        : text,
            magic_token : '<mt:var magic_token>'
        };
        jQuery.post ('<mt:var script_url>', request_param);

        // Forward to Cancel button to finish the editing
        jQuery(this).siblings('span.action-icon.cancel').click();
    });
</script>
MTMLHEREDOC
    $$tmpl =~ s/$/$new/;

    ### Styles
    chomp ($new = &instance->translate_templatized (<<'MTMLHEREDOC'));
<style type="text/css">
    .icon-close {
        background-image:url('<mt:var static_uri>images/status_icons/close.gif'); }
    span.revision-changed {
        font-size:80%; font-style:italic; color:#444; }
    span.revision-number {
        font-size:80%; }
</style>
MTMLHEREDOC
    $$tmpl =~ s/^/$new/;
}

1;