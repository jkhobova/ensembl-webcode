=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::HTML::GalleryHome;

### Simple form providing an entry to the new Site Gallery navigation system 

use strict;
use warnings;

use EnsEMBL::Web::Form;
use EnsEMBL::Web::Component;

use base qw(EnsEMBL::Web::Document::HTML);

sub render {
  my $self = shift;
  my $html;

  my $hub           = $self->hub;
  my $species_defs  = $hub->species_defs;
  my $sitename      = $species_defs->ENSEMBL_SITETYPE;

  ## Check session for messages
  my $error = $hub->session->get_data('type' => 'message', 'code' => 'gallery');

  if ($error) {
    $html .= sprintf(
      '<div style="width:95%" class="warning"><h3>Error</h3><div class="message-pad"><p>%s</p></div></div>', $error->{'message'});
    $hub->session->purge_data(type => 'message', code => 'gallery');
  }

  $html .= '<div class="js_panel" id="site-gallery-home">
      <input type="hidden" class="panel_type" value="SiteGalleryHome">';

  my $form      = EnsEMBL::Web::Form->new({'id' => 'gallery_home', 'action' => '/Info/CheckGallery', 'class' => 'add_species_on_submit', 'name' => 'gallery_home'});
  my $fieldset  = $form->add_fieldset({});

  my (@array, %sample_data);
  foreach ($species_defs->valid_species) {
    my $class = ['_stt'];
    push @$class, $hub->species_defs->get_config($_, 'databases')->{'DATABASE_VARIATION'} 
                  ? '_stt__var' : '_stt__novar';
    push @array, {'value' => $_, 'class' => $class,
                  'caption' => $species_defs->get_config($_, 'SPECIES_COMMON_NAME')};
    $sample_data{$_} =  $species_defs->get_config($_, 'SAMPLE_DATA');
  }

  my @species     = sort {$a->{'caption'} cmp $b->{'caption'}} @array;
  my $favourites  = $hub->get_favourite_species;
  $fieldset->add_field({
                        'type'    => 'Dropdown',
                        'name'    => 'species',
                        'label'   => 'Species',
                        'class'   => '_stt',
                        'values'  => \@species,
                        'value'   => $favourites->[0],
                        });


  ## Two radiolists, with and without variants

  my $data_types = [
                    {'value' => 'Gene',       'caption' => 'Genes'},
                    {'value' => 'Location',   'caption' => 'Genomic locations'},
                    ];

  my %params = (
                'type'        => 'Radiolist',
                'name'        => 'data_type_novar',
                'label'       => 'Feature type',
                'field_class' => '_stt_novar',
                'values'      => $data_types,
                'value'       => 'Gene',
                );
  $fieldset->add_field(\%params);

  push @$data_types, {'value' => 'Variation',  'caption' => 'Variants'};

  my %var_params = %params;
  $var_params{'name'}         = 'data_type_var';
  $var_params{'field_class'}  = '_stt_var';
  $var_params{'values'}       = $data_types;
  $fieldset->add_field(\%var_params);

  ## Add hidden fields for default values for every species, for use by JavaScript
  while (my($species, $examples) = each(%sample_data)) {
    foreach (@$data_types) {
      my $type  = $_->{'value'};
      my $key   = uc($type).'_PARAM';
      my $value = $examples->{$key};
      if ($value) {
        $fieldset->add_hidden({
                              'name'    => $species.'-'.$type,
                              'value'   => $value,
                            });
      }
    }
  }

  $fieldset->add_field({
                        'type'    => 'String',
                        'name'    => 'identifier',
                        'label'   => 'Identifier',
                        });

  $fieldset->add_button({
    'name'      => 'submit',
    'value'     => 'Go',
    'class'     => 'submit'
  });

  $html .= $form->render;

  $html .= '</div>';

  return $html; 
}

1;
