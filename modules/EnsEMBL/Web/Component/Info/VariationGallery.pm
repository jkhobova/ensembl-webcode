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
                    'pages' => ['Region in Detail', 'Genomic Context', 'Flanking Sequence', 'Phylogenetic Context', 'LD Image'],
                    'icon'  => 'karyotype.png',
                  },
                  {
                    'title' => 'Genes',
                    'pages' => ['Gene Sequence', 'Gene Table', 'Gene Image', 'Gene Regulation', 'Citations'],
                    'icon'  => 'dna.png',
                  },
                  {
                    'title' => 'Transcripts',
                    'pages' => ['Transcript Image', 'Transcript Table', 'Transcript Comparison', 'Exons', 'Gene Regulation', 'Citations'],
                    'icon'  => 'transcripts.png',
                  },
                  {
                    'title' => 'Proteins',
                    'pages' => ['Protein Summary', 'cDNA Sequence', 'Protein Sequence', 'Variation Protein', 'Citations'],
                    'icon'  => 'protein.png',
                  },
                  {
                    'title' => 'Phenotypes',
                    'pages' => ['Phenotype Table', 'Gene Phenotype', 'Phenotype Karyotype', 'Phenotype Location Table', 'Citations'],
                    'icon'  => 'var_phenotype_data.png',
                  },
                  {
                    'title' => 'Populations &amp; Individuals',
                    'pages' => ['Population Image', 'Population Table', 'Genotypes Table', 'LD Image', 'LD Table', 'Resequencing', 'Citations'],
                    'icon'  => 'var_sample_information.png',
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
  my ($no_phenotype, $multi_phenotype) = (0, 0);

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
                          'values'  => [{'value' => '', 'caption' => '-- Select coordinates --'}],
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
        $genes{$gene->stable_id} = $self->gene_name($gene) if $gene;
      }
    }

    if (scalar keys %genes) {
      if (scalar keys %genes > 1) {
        $multi_gene = {
                          'type'    => 'Gene',
                          'param'   => 'g',
                          'values'  => [{'value' => '', 'caption' => '-- Select gene --'}],
                          };
        foreach (sort {$genes{$a} cmp $genes{$b}} keys %genes) {
          push @{$multi_gene->{'values'}}, {'value' => $_, 'caption' => $genes{$_}};
        }
      }
      else {
        my @ids = keys %genes;
        $g = $ids[0];
      }
    }

    ## Phenotype checking
    my $pfs = $object->get_ega_links;
    if (scalar($pfs)) {
      if (scalar($pfs) > 1) {
        $multi_phenotype = {
                          'type'    => 'Phenotype',
                          'param'   => 'ph',
                          'values'  => [{'value' => '', 'caption' => '-- Select phenotype --'}],
                          };
        foreach (@$pfs) {
          my $id = $_->{'_phenotype_id'};
          my $name = $_->phenotype->description;
          push @{$multi_phenotype->{'values'}}, {'value' => $id, 'caption' => $name};
        }
      }
    }
    else {
      $no_phenotype = 1;
    }


    return {'Region in Detail' => {
                                  'url'       => $hub->url({'type'    => 'Location',
                                                          'action'  => 'View',
                                                          'v'      => $v,
                                                          }),
                                  'img'       => 'variation_location',
                                  'caption'   => 'Region where your variant is located',
                                  'multi'     => $multi_location,  
                                  'disabled'  => $no_location,  
                                },
          'Genomic Context' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action' => 'Context',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_genomic',
                                  'caption' => 'Genomic context of your variant',
                                },
          'Flanking Sequence' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'Sequence',
                                                          'v'      => $v,
                                                          }),
                                  'img'     => 'variation_sequence',
                                  'caption' => 'Flanking sequence for your variant',
                                  },
          'Phylogenetic Context' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'Compara_Alignments',
                                                          'v'      => $v,
                                                          }),
                                  'img'     => 'variation_phylogenetic',
                                  'caption' => 'Phylogenetic context of your variant',
                                  },
          'Gene Sequence' => {
                                  'url'       => $hub->url({'type'  => 'Gene',
                                                          'action'  => 'Sequence',
                                                          'v'       => $v,
                                                          'g'       => $g,
                                                          }),
                                  'img'       => 'variation_gene_seq',
                                  'caption'   => 'Sequence of the gene overlapping your variant',
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
                                  'caption'   => 'Image showing all variants in the same gene as this one',
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
                                  'caption'   => 'Table of all variants in the same gene as this one',
                                  'multi'     => $multi_gene,  
                                  'disabled'  => $no_gene,  
                          },
          'Gene Regulation' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'Mappings',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_mappings',
                                  'caption' => 'Genes and regulatory features around your variant',
                                },
          'Citations' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'Citations',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_citations',
                                  'caption' => 'Papers citing your variant',
                                },
          'Transcript Image' => {
                                  'url'     => $hub->url({'type'    => 'Transcript',
                                                          'action'  => 'Variation_Transcript/Image',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_trans_image',
                                  'caption' => 'Image showing all variants within the same transcript as this one',
                                  'disabled'  => $no_gene,  
                                },
          'Transcript Table' => {
                                  'url'     => $hub->url({'type'    => 'Transcript',
                                                          'action'  => 'Variation_Transcript/Table',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_trans_table',
                                  'caption' => 'Table of variants within the same transcript as this one',
                                  'disabled'  => $no_gene,  
                                },
          'Transcript Comparison' => {
                                  'url'     => $hub->url({'type'    => 'Gene',
                                                          'action'  => 'TranscriptComparison',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_trans_comp',
                                  'caption' => "Comparison of a gene's transcripts, showing variants",
                                  'disabled'  => $no_gene,  
                                },
          'Exons' => {
                                  'url'     => $hub->url({'type'    => 'Transcript',
                                                          'action'  => 'Exons',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_exons',
                                  'caption' => 'Variations within each exon sequence',
                                  'disabled'  => $no_gene,  
                                },
          'Protein Summary' => {
                                  'url'     => $hub->url({'type'    => 'Transcript',
                                                          'action'  => 'ProteinSummary',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_protein',
                                  'caption' => "Variants on a protein's domains",
                                  'disabled'  => $no_gene,  
                                },
          'cDNA Sequence' => {
                                  'url'     => $hub->url({'type'    => 'Transcript',
                                                          'action'  => 'Sequence_cDNA',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_cdna_seq',
                                  'caption' => 'Variants on cDNA sequence',
                                  'disabled'  => $no_gene,  
                                },
          'Protein Sequence' => {
                                  'url'     => $hub->url({'type'    => 'Transcript',
                                                          'action'  => 'Sequence_Protein',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_protein_seq',
                                  'caption' => 'Variants on protein sequence',
                                  'disabled'  => $no_gene,  
                                },
          'Variation Protein' => {
                                  'url'     => $hub->url({'type'    => 'Transcript',
                                                          'action'  => 'ProtVariations',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_protvars',
                                  'caption' => 'Table of variants for a protein',
                                  'disabled'  => $no_gene,  
                                },
          'Phenotype Table' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'Phenotype',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_phenotype',
                                  'caption' => 'Phenotypes associated with your variant',
                                  'multi'     => $multi_phenotype,  
                                  'disabled'  => $no_phenotype,  
                                },
          'Gene Phenotype' => {
                                  'url'     => $hub->url({'type'    => 'Gene',
                                                          'action'  => 'Phenotype',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_gen_phen',
                                  'caption' => 'Phenotypes associated with a gene which overlaps your variant',
                                  'multi'     => $multi_phenotype,  
                                  'disabled'  => $no_phenotype,  
                                },
          'Phenotype Karyotype' => {
                                  'url'     => $hub->url({'type'    => 'Phenotype',
                                                          'action'  => 'Locations',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_karyotype',
                                  'caption' => 'Locations of all variants associated with the same phenotype as this one',
                                  'multi'     => $multi_phenotype,  
                                  'disabled'  => $no_phenotype,  
                                },
          'Phenotype Location Table' => {
                                  'url'     => $hub->url({'type'    => 'Phenotype',
                                                          'action'  => 'Locations',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_phen_table',
                                  'caption' => 'Table of variants associated with the same phenotype as this one',
                                  'multi'     => $multi_phenotype,  
                                  'disabled'  => $no_phenotype,  
                                },
          'Population Table' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'Population',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_pop_table',
                                  'caption' => 'Table of allele frequencies in different populations',
                                },
          'Population Image' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'Population',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_pop_piecharts',
                                  'caption' => 'Pie charts of allele frequencies in different populations',
                                },
          'Genotypes Table' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'Sample',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_sample',
                                  'caption' => 'Genotypes for samples within a population',
                                },
          'LD Image' => {
                                  'url'       => $hub->url({'type'    => 'Location',
                                                          'action'  => 'LD',
                                                          'v'      => $v,
                                                        }),
                                  'img'       => 'variation_ld_image',
                                  'caption'   => 'Linkage disequilibrium plot in a region',
                                  'multi'     => $multi_location,  
                                  'disabled'  => $no_location,  
                                },
          'LD Table' => {
                                  'url'     => $hub->url({'type'    => 'Variation',
                                                          'action'  => 'HighLD',
                                                          'v'      => $v,
                                                        }),
                                  'img'     => 'variation_ld_table',
                                  'caption' => 'Linkage disequilibrium with your variant',
                                },
          'Resequencing' => {
                                  'url'       => $hub->url({'type'    => 'Location',
                                                          'action'  => 'SequenceAlignment',
                                                          'v'      => $v,
                                                        }),
                                  'img'       => 'variation_resequencing',
                                  'caption'   => 'Variants in resequenced samples',
                                  'multi'     => $multi_location,  
                                  'disabled'  => $no_location,  
                                },
    };
  }
}

1;
