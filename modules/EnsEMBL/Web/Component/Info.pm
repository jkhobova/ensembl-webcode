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

package EnsEMBL::Web::Component::Info;

use strict;

use base qw(EnsEMBL::Web::Component);

use warnings;

use EnsEMBL::Web::DBSQL::ArchiveAdaptor;

use parent qw(EnsEMBL::Web::Component::Shared);

sub assembly_dropdown {
  my $self              = shift;
  my $hub               = $self->hub;
  my $adaptor           = EnsEMBL::Web::DBSQL::ArchiveAdaptor->new($hub);
  my $species           = $hub->species;
  my $archives          = $adaptor->fetch_archives_by_species($species);
  my $species_defs      = $hub->species_defs;
  my $pre_species       = $species_defs->get_config('MULTI', 'PRE_SPECIES');
  my $done_assemblies   = { map { $_ => 1 } $species_defs->ASSEMBLY_NAME, $species_defs->ASSEMBLY_VERSION };

  my @assemblies;

  foreach my $version (reverse sort {$a <=> $b} keys %$archives) {

    my $archive           = $archives->{$version};
    my $archive_assembly  = $archive->{'version'};

    if (!$done_assemblies->{$archive_assembly}) {

      my $desc      = $archive->{'description'} || sprintf '(%s release %s)', $species_defs->ENSEMBL_SITETYPE, $version;
      my $subdomain = ((lc $archive->{'archive'}) =~ /^[a-z]{3}[0-9]{4}$/) ? lc $archive->{'archive'}.'.archive' : lc $archive->{'archive'};

      push @assemblies, {
        url      => sprintf('http://%s.ensembl.org/%s/', $subdomain, $species),
        assembly => $archive_assembly,
        release  => $desc,
      };

      $done_assemblies->{$archive_assembly} = 1;
    }
  }

  ## Don't link to pre site on archives, as it changes too often
  push @assemblies, { url => "http://pre.ensembl.org/$species/", assembly => $pre_species->{$species}[1], release => '(Ensembl pre)' } if ($pre_species->{$species} && $species_defs->ENSEMBL_SITETYPE !~ /archive/i);

  my $html = '';

  if (scalar @assemblies) {
    if (scalar @assemblies > 1) {
      $html .= qq(<form action="/$species/redirect" method="get"><select name="url">);
      $html .= qq(<option value="$_->{'url'}">$_->{'assembly'} $_->{'release'}</option>) for @assemblies;
      $html .= '</select> <input type="submit" name="submit" class="fbutton" value="Go" /></form>';
    } else {
      $html .= qq(<ul><li><a href="$assemblies[0]{'url'}" class="nodeco">$assemblies[0]{'assembly'}</a> $assemblies[0]{'release'}</li></ul>);
    }
  }

  return $html;
}

our $data_type = {
                  'Gene'      => {'param'   => 'g', 
                                  'label_1' => 'Choose a Gene',
                                  'label_2' => 'or choose another Gene',
                                  },
                  'Variation' => {'param'   => 'v', 
                                  'label_1' => 'Choose a Variant',
                                  'label_2' => 'or choose another Variant',
                                  },
                  'Location'  => {'param'   => 'r', 
                                  'label_1' => 'Choose Coordinates',
                                  'label_2' => 'or choose different coordinates'
                                  },
                  };


sub format_gallery {
  my ($self, $type, $layout, $all_pages) = @_;
  my ($html, @toc);

  return unless $all_pages;

  foreach my $group (@$layout) {
    my @pages = @{$group->{'pages'}||[]};
    #next unless scalar @pages;

    my $title = $group->{'title'};
    push @toc, sprintf('<a href="#%s">%s</a>', lc($title), $title);
    $html .= sprintf('<h2 id="%s">%s</h2>', lc($title), $title);

    $html .= '<div class="gallery">';

    foreach (@pages) {
      my $page = $all_pages->{$_};
      next unless $page;

      $html .= '<div class="gallery_preview">';

      if ($page->{'disabled'}) {
        ## Disable views that are invalid for this feature
        $html .= sprintf('<div class="preview_caption">%s<br />[Not available for this %s]</div><br />', $page->{'caption'}, lc($type));
        $html .= sprintf('<img src="/i/gallery/%s.png" class="disabled" /></a>', $page->{'img'});
      }
      elsif ($page->{'multi'}) {
        ## Disable links on views that can't be mapped to a single feature/location
        $html .= sprintf('<div class="preview_caption">%s<br />N.B. Maps to multiple %s</div><br />', $page->{'caption'}, lc($type).'s');
        $html .= sprintf('<img src="/i/gallery/%s.png" /></a>', $page->{'img'});
      }
      else {
        $html .= sprintf('<div class="preview_caption"><a href="%s" class="nodeco">%s</a></div><br />', $page->{'url'}, $page->{'caption'});

        $html .= sprintf('<a href="%s"><img src="/i/gallery/%s.png" /></a>', $page->{'url'}, $page->{'img'});
      }

      my $form = $self->new_form({'action' => $page->{'url'}, 'method' => 'post'});

      my ($field, $data_param);
      my $label = $self->hub->param('default') ? 'label_1' : 'label_2';
      my $value = $self->hub->param('default') ? $self->hub->param($data_param) : undef;

      if ($page->{'multi'}) {
        $data_param = $page->{'multi'}{'param'};
        $type       = $page->{'multi'}{'type'};
        $field      = $form->add_field({
                                        'type'    => 'Dropdown',
                                        'name'    => $data_param,
                                        'label'   => $data_type->{$type}{$label},
                                        'values'  => $page->{'multi'}{'values'},
                                        'value'   => $value,
                                        });
      }
      else {
        $data_param = $data_type->{$type}{'param'};
        $field      = $form->add_field({
                                        'type'  => 'String',
                                        'size'  => 10,
                                        'name'  => $data_param,
                                        'label' => $data_type->{$type}{$label},
                                        'value' => $value,
                                        });
      }

      $field->add_element({'type' => 'submit', 'value' => 'Go'}, 1);

      $html .= '<div style="width:300px">'.$form->render.'</div>';

      $html .= '</div>';
    }

    $html .= '</div>';
  }
  my $toc_string = sprintf('<p class="center">%s</p>', join(' | ', @toc));

  return $toc_string.$html;  
}

1;
