package Bio::EnsEMBL::GlyphSet::ensembl_genscan;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet_feature;
@ISA = qw(Bio::EnsEMBL::GlyphSet_feature);

sub my_label { return "Ens. Genscan pep."; }

sub features {
    my ($self) = @_;
    return $self->{'container'}->get_all_SimilarityFeatures_by_strand("ensembl_genscan",1,$self->glob_bp,$self->strand());
}

sub href {
    my ($self, $id ) = @_;
    $id =~ s/(.*)\.\d+/$1/o;
    return $self->{'config'}->{'ext_url'}->get_url( 'ENS_GENSCAN', $id );
}
sub zmenu {
    my ($self, $id ) = @_;
    #marie - uses local bioperl db to serve up protein homology
    return {
        'caption' => "$id",
            "Protein homology" =>  $self->href($id)

    };
}
1;

