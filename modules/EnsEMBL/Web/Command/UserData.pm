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

package EnsEMBL::Web::Command::UserData;

use strict;

use HTML::Entities qw(encode_entities);

use EnsEMBL::Web::File::User;
use EnsEMBL::Web::Utils::Feedback qw(add_userdata_message);

use base qw(EnsEMBL::Web::Command);

sub ajax_redirect {
  ## Provide default value for redirectType and modalTab
  my ($self, $url, $param, $anchor, $redirect_type, $modal_tab) = @_;
  $self->SUPER::ajax_redirect($url, $param, $anchor, $redirect_type || 'modal', $modal_tab || 'modal_user_data');
}

sub upload {
### Separate out the upload, to make code reuse easier
### TODO refactor this method as a wrapper around E::W::File::User::upload
### - all it needs to do is return the required parameters
  my ($self, $method, $type) = @_;
  my $hub       = $self->hub;
  my $params    = {};

  my $error = $hub->input->cgi_error;

  if ($error =~ /413/) {
    add_userdata_message($hub->session, 'file_size');      
  }
 
  my $file = EnsEMBL::Web::File::User->new('hub' => $hub);
  my $error = $file->upload({'method' => $method, 'type' => $type});

  if ($error) {
    $hub->session->add_data(
                            'type'      => 'message',
                            'code'      => 'user_upload_failure',
                            'function'  => '_warning',
                            'message'   => $error,
                            );
  }
  else {
    return {
          'name'    => $file->write_name,
          'format'  => $file->format,
          'species' => $hub->param('species') || $hub->species,
          'code'    => $file->code,
          }; 
  }
}

sub attach_data {
  my ($self, $url, $format) = @_;
  my $params;

  my $file = EnsEMBL::Web::File::User->new('hub' => $self->hub, 'file' => $url);

  return $params;
}

1;
