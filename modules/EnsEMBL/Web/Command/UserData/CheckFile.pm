=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Command::UserData::CheckFile;

use strict;
use warnings;
no warnings 'uninitialized';

use HTML::Entities qw(encode_entities);

use base qw(EnsEMBL::Web::Command::UserData);

sub process {
  my $self = shift;
  my $hub  = $self->hub;

  my $format    = $hub->param('format');  
  my ($method)  = grep $hub->param($_), qw(file url text);
  my $url_params;

  if ($method eq 'url') {
    $url_params = $self->attach_data($hub->param('url'), $format);
    $url_params->{'action'} = 'RemoteFeedback';
  }
  elsif ($method) { ## Upload data
    $url_params = $self->upload($method, $format);
    $url_params->{'action'} = 'UploadFeedback';
  }

  return $self->ajax_redirect($self->hub->url($url_params));
}

1;
