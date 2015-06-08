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

package EnsEMBL::Web::Utils::Feedback;

## Utility methods to quickly add feedback to a page

use strict;
use warnings;

use EnsEMBL::Web::Constants;
use EnsEMBL::Web::Exceptions;

use Exporter qw(import);
our @EXPORT_OK = qw(add_userdata_message);

sub add_userdata_message {
### Add a message to the session upon data error
  my ($session, $key) = @_;
  my %data_error = EnsEMBL::Web::Constants::USERDATA_MESSAGES;
  my $error = $data_error{$key};

  unless ($error) {
    throw exception('UserData', "Error message for $key not defined. Please check EnsEMBL::Web::Constants::USERDATA_MESSAGES");
  }

  $session->add_data(
      type     => 'message',
      code     => 'userdata_'.$key,
      message  => $error->{'message'},
      function => '_'.$error->{'type'},
  );
}


1;

