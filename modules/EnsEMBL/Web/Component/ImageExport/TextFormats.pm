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

package EnsEMBL::Web::Component::ImageExport::TextFormats;

use strict;
use warnings;

use HTML::Entities qw(encode_entities);

use EnsEMBL::Web::Constants;

use parent qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
  $self->configurable( 0 );
}

sub content {
  ### Options for gene sequence output
  my $self  = shift;
  my $hub   = $self->hub;

  my $form = $self->new_form({'id' => 'export', 'action' => $hub->url({'action' => 'Output',  '__clear' => 1}), 'method' => 'post', 'class' => 'freeform-stt'});

  my $fieldset = $form->add_fieldset({'legend' => 'What would you like to export?'});

  my $values = [
                {'value' => 'sequence', 'caption' => 'FASTA sequence for this region', 'class' => '_stt _stt__sequence' },
                {'value' => 'tracks',   'caption' => 'Tracks displayed in this image', 'class' => '_stt _stt__tracks' },
                {'value' => 'other',    'caption' => 'A larger data set (e.g. all genes, or multiple regions)', 'class' => '_stt _stt__other' },
                ];

  $fieldset->add_field({
        'type'    => 'Radiolist',
        'name'    => 'next_acion',
        'class'   => '_stt',
        'value'   => 'tracks',
        'values'  => $values,
  });

  my $compress = {
                  'type'    => 'Radiolist',
                  'name'    => 'compression',
                  'values'  => [
                                {'caption' => 'Uncompressed', 'value' => '', 'checked' => 1},
                                {'caption' => 'Gzip', 'value' => 'gz'},
                                ],
                  'notes'   => 'Select "uncompressed" to get a preview of your file',
  };

  ## Sequence options
  my $sequence = $form->add_fieldset({'class' => '_stt_sequence', 'legend' => 'Options'});

  $sequence->add_field({
        'type'  => 'Dropdown',
        'name'  => 'masking',
        'values'  => [
                      {'value' => '',     'caption' => 'Unmasked'},
                      {'value' => 'soft', 'caption' => 'Repeat masked (soft)'},
                      {'value' => 'hard', 'caption' => 'Repeat masked (hard)'},
                      ],
  });


  $sequence->add_field($compress);

  $sequence->add_button({
        'type'        => 'Submit',
        'name'        => 'submit',
        'value'       => 'Download',
  }); 

  ## Track options
  my $track_opts = $form->add_fieldset({'class' => '_stt_tracks', 'legend' => 'Options'});

  my $formats = [
                {'value' => 'bed', 'caption' => 'BED'},
                {'value' => 'gff', 'caption' => 'GFF'},
                {'value' => 'gtf', 'caption' => 'GTF'},
                ];

  $track_opts->add_field({
        'type'    => 'Dropdown',
        'name'    => 'format',
        'value'   => 'gff',
        'values'  => $formats,
  });

  $track_opts->add_field({
        'type'    => 'Radiolist',
        'name'    => 'select_tracks',
        'value'   => 'all',
        'values'  => [
                      {'value' => 'all', 'caption' => 'All visible feature tracks'},
                      {'value' => 'selection', 'caption' => 'Selected tracks only'},
                      ],
  });

  $track_opts->add_field($compress);

  $track_opts->add_button({
        'type'        => 'Submit',
        'name'        => 'submit',
        'value'       => 'Download',
  }); 

  ## Biomart link
  my $biomart = $form->add_fieldset({'class' => '_stt_other'});

  $biomart->add_notes({'text' => '<img src="/i/biomart_thumb.gif" /> 
<b>The Biomart data-mining tool allows you to create custom queries for large data sets.</b>'});

  $biomart->add_button({
        'type'        => 'Submit',
        'name'        => 'submit',
        'value'       => 'Try it',
  });

  return '<h1>Download data from image</h1>'.$form->render;
}

sub format_options {
  my $self = shift;

  my $text_formats = [
                      {'value' => '',       'caption' => '-- Choose --'},
                      {'value' => 'fasta',  'caption' => 'FASTA sequence'},
                      {'value' => 'bed',    'caption' => 'BED'},
                      {'value' => 'gff',    'caption' => 'GFF'},
                      {'value' => 'gff3',   'caption' => 'GFF3'},
                      {'value' => 'gtf',    'caption' => 'GTF'},
                      ];

  my $options = {
    'text'      => [
                    {'type' => 'Dropdown', 'name' => 'text_format', 'label' => 'format', 
                      'values' => $text_formats, 'class' => '_stt'},
                    {'type' => 'Radiolist', 'name' => 'compression', 'label' => 'Output',
                      'notes' => 'Select "uncompressed" to get a preview of your file',
                      'values' => [
                                    {'caption' => 'Uncompressed', 'value' => '', 'checked' => 1},
                                    {'caption' => 'Gzip', 'value' => 'gz'}]
                    },
                    ],
  };

  return $options;
}

sub default_file_name {
  my $self = shift;
  my $name = $self->hub->species;
  my $data_object = $self->hub->param('g') ? $self->hub->core_object('gene') : undef;
  if ($data_object) {
    $name .= '_';
    my $stable_id = $data_object->stable_id;
    my ($disp_id) = $data_object->display_xref;
    $name .= $disp_id || $stable_id;
  }
  $name .= '_download';
  return $name;
}

1;
