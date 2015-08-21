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

package EnsEMBL::Web::Component::Info::VariationGallery;

## 

use strict;

use base qw(EnsEMBL::Web::Component::Info);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self = shift;

  ## Define page layout 
  ## Note: We structure it like this, because for improved findability, pages can appear 
  ## under more than one heading. Configurations for individual views are defined in a
  ## separate method, lower down this module
  my $layout = [
                  {
                    'title' => 'Locations',                      
                    'pages' => ['Region in Detail', 'Genomic Context', 'Flanking Sequence', 'Phylogenetic Context'],
                  },
                  {
                    'title' => 'Genes',
                    'pages' => ['Gene Sequence', 'Gene Table', 'Gene Image', 'Gene Regulation', 'Citations'],
                  },
                  {
                    'title' => 'Transcripts',
                    'pages' => ['Transcript Image', 'Transcript Table', 'Transcript Comparison', 'Exons', 'Gene Regulation', 'Citations'],
                  },
                  {
                    'title' => 'Proteins',
                    'pages' => ['Protein Summary', 'cDNA Sequence', 'Protein Sequence', 'Variation Protein', 'Citations'],
                  },
                  {
                    'title' => 'Phenotypes',
                    'pages' => ['Phenotype Table', 'Gene Phenotype', 'Phenotype Karyotype', 'Phenotype Location Table', 'Citations'],
                  },
                  {
                    'title' => 'Populations &amp; Individuals',
                    'pages' => ['Population Image', 'Population Table', 'Genotypes Table', 'LD Image', 'LD Table', 'Resequencing', 'Citations'],
                  },
                ];

  my $pages = $self->_get_pages;

  if (ref($pages) eq 'HASH') {
    return $self->format_gallery('Variation', $layout, $pages);
  }
  else {
    return $pages; ## error message
  }

}

sub _get_pages {
  ## Define these in a separate method to make content method cleaner
  my $self = shift;
  my $hub = $self->hub;
  my $v = $hub->param('v');

  ## Check availabity of views for this variant
  my ($no_location, $multi_location) = (0, 0);
  my ($no_gene, $multi_gene) = (0, 0);

  my $builder   = $hub->{'_builder'};
  my $factory   = $builder->create_factory('Variation');
  my $object    = $factory->object;

  if (!$object) {
    return $self->warning_panel('Invalid identifier', 'Sorry, that identifier could not be found. Please try again.');
  }
  else {
    ## Location checking
    my %mappings = %{$object->variation_feature_mapping};
    if (scalar keys %mappings == 0) {
      $no_location = 1;
      $no_gene = 1;
    }
    elsif (scalar keys %mappings > 1) {
      $multi_location = {
                          'type'    => 'Location',
                          'param'   => 'r',
                          'values'  => [],
                          };
      foreach (sort { $mappings{$a}{'Chr'} cmp $mappings{$b}{'Chr'} || $mappings{$a}{'start'} <=> $mappings{$b}{'start'}} keys %mappings) {
        my $coords = sprintf('%s:%s-%s', $mappings{$_}{'Chr'}, $mappings{$_}{'start'}, $mappings{$_}{'end'});
        push @{$multi_location->{'values'}}, {'value' => $coords, 'caption' => $coords};
      }
    }

    ## Gene checking
    my ($g, %genes);
    my $gene_adaptor  = $hub->get_adaptor('get_GeneAdaptor');
    foreach my $varif_id (grep $_ eq $hub->param('vf'), keys %mappings) {
      foreach my $transcript_data (@{$mappings{$varif_id}{'transcript_vari'}}) {
        my $gene = $gene_adaptor->fetch_by_transcript_stable_id($transcript_data->{'transcriptname'}); 
        $genes{$gene->stable_id}++ if $gene;
      }
    }

    if (scalar keys %genes) {
      if (scalar keys %genes > 1) {
        $multi_gene = {
                          'type'    => 'Gene',
                          'param'   => 'g',
                          'values'  => [],
                          };
        foreach (sort keys %genes) {
          push @{$multi_gene->{'values'}}, {'value' => $_, 'caption' => $_};
        }
      }
      else {
        my @ids = keys %genes;
        $g = $ids[0];
      }
    }

    return {'Region in Detail' => {
                                  'url'       => $hub->url({'type'    => 'Location',
                                                          'action'  => 'View',
                                                          'v'      => $v,
                                                          }),
                                  'img'       => 'variation_location',
                                  'caption'   => 'Region where this variant is located',
                                  'multi'     => $multi_location,  
                                  'disabled'  => $no_location,  
                                },
          'Genomic Context' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action' => 'Context',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_genomic',
                                  'caption' => 'Genomic context of this variant',
                                },
          'Flanking Sequence' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'Sequence',
                                                          'v'      => $v,
                                                          }),
                                  'img'     => 'variation_sequence',
                                  'caption' => 'Flanking sequence for this variant',
                                  },
          'Phylogenetic Context' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'Compara_Alignments',
                                                          'v'      => $v,
                                                          }),
                                  'img'     => 'variation_phylogenetic',
                                  'caption' => 'Phylogenetic context of this variant',
                                  },
          'Gene Sequence' => {
                                  'url'       => $hub->url({'type'  => 'Gene',
                                                          'action'  => 'Sequence',
                                                          'v'       => $v,
                                                          'g'       => $g,
                                                          }),
                                  'img'       => 'variation_gene_seq',
                                  'caption'   => 'Sequence of the gene overlapping this variant',
                                  'multi'     => $multi_gene,  
                                  'disabled'  => $no_gene,  
                            },
          'Gene Image' => {
                                  'url'       => $hub->url({'type'    => 'Gene',
                                                          'action'  => 'Variation_Gene/Image',
                                                          'v'       => $v,
                                                          'g'       => $g,
                                                          }),
                                  'img'       => 'variation_gene_image',
                                  'caption'   => 'Image showing all variants within the same gene as this one',
                                  'multi'     => $multi_gene,  
                                  'disabled'  => $no_gene,  
                          },
          'Gene Table' => {
                                  'url'       => $hub->url({'type'    => 'Gene',
                                                          'action'  => 'Variation_Gene/Table',
                                                          'v'      => $v,
                                                          'g'       => $g,
                                                        }),
                                  'img'       => 'variation_gene_table',
                                  'caption'   => 'Table of variants within the same gene as this one',
                                  'multi'     => $multi_gene,  
                                  'disabled'  => $no_gene,  
                          },
          'Gene Regulation' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'Mappings',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_mappings',
                                  'caption' => 'Genes and regulatory features around this variant',
                                },
          'Citations' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'Citations',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_citations',
                                  'caption' => 'Papers citing this variant',
                                },
          'Transcript Image' => {
                                  'url'     => $hub->url({'type'    => 'Transcript',
                                                          'action'  => 'Variation_Transcript/Image',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_trans_image',
                                  'caption' => '',
                                },
          'Transcript Table' => {
                                  'url'     => $hub->url({'type'    => 'Transcript',
                                                          'action'  => 'Variation_Transcript/Table',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_trans_table',
                                  'caption' => 'Table of variants within the same transcript as this one',
                                },
          'Transcript Comparison' => {
                                  'url'     => $hub->url({'type'    => 'Gene',
                                                          'action'  => 'TranscriptComparison',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_trans_comp',
                                  'caption' => '',
                                },
          'Exons' => {
                                  'url'     => $hub->url({'type'    => 'Transcript',
                                                          'action'  => 'Exons',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_exons',
                                  'caption' => 'Variations within each exon sequence',
                                },
          'Protein Summary' => {
                                  'url'     => $hub->url({'type'    => 'Transcript',
                                                          'action'  => 'ProteinSummary',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_protein',
                                  'caption' => "Variants on a protein's domains",
                                },
          'cDNA Sequence' => {
                                  'url'     => $hub->url({'type'    => 'Transcript',
                                                          'action'  => 'Sequence_cDNA',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_cdna_seq',
                                  'caption' => 'Variants on cDNA sequence',
                                },
          'Protein Sequence' => {
                                  'url'     => $hub->url({'type'    => 'Transcript',
                                                          'action'  => 'Sequence_Protein',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_protein_seq',
                                  'caption' => 'Variants on protein sequence',
                                },
          'Variation Protein' => {
                                  'url'     => $hub->url({'type'    => 'Transcript',
                                                          'action'  => 'ProtVariations',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_protvars',
                                  'caption' => 'Table of variants for a protein',
                                },
          'Phenotype Table' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'Phenotype',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_phenotype',
                                  'caption' => '',
                                },
          'Gene Phenotype' => {
                                  'url'     => $hub->url({'type'    => 'Gene',
                                                          'action'  => 'Phenotype',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_gen_phen',
                                  'caption' => '',
                                },
          'Phenotype Karyotype' => {
                                  'url'     => $hub->url({'type'    => 'Phenotype',
                                                          'action'  => 'Locations',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_karyotype',
                                  'caption' => '',
                                },
          'Phenotype Location Table' => {
                                  'url'     => $hub->url({'type'    => 'Phenotype',
                                                          'action'  => 'Locations',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_phen_table',
                                  'caption' => '',
                                },
          'Population Table' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'Population',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_pop_table',
                                  'caption' => '',
                                },
          'Population Image' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'Population',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_pop_piecharts',
                                  'caption' => '',
                                },
          'Genotypes Table' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'Individual',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_individual',
                                  'caption' => '',
                                },
          'LD Image' => {
                                  'url'       => $hub->url({'type'    => 'Location',
                                                          'action'  => 'LD',
                                                          'v'      => $v,
                                                        }),
                                  'img'       => 'variation_ldview',
                                  'caption'   => '',
                                  'multi'     => $multi_location,  
                                  'disabled'  => $no_location,  
                                },
          'LD Table' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'HighLD',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_highld',
                                  'caption' => '',
                                },
          'Resequencing' => {
                                  'url'       => $hub->url({'type'    => 'Location',
                                                          'action'  => 'SequenceAlignment',
                                                          'v'      => $v,
                                                        }),
                                  'img'       => 'variation_resequencing',
                                  'caption'   => '',
                                  'multi'     => $multi_location,  
                                  'disabled'  => $no_location,  
                                },
    };
  }
}

1;
