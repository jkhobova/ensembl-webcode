package Bio::EnsEMBL::GlyphSet::fg_background_regulation;

use strict;

use base qw(Bio::EnsEMBL::GlyphSet);
#needed to shade the region covered by a regulatory feature in regulation detailed view.


sub _init {
  my ($self) = @_;  
  my $Config = $self->{'config'};
  my $slice = $self->{'container'}; 
  my $target_feature_id = $self->{'config'}->core_objects->regulation->stable_id;  
  my $strand = $self->strand; 
  my $colour = 'lightcoral';
  my $x = 0;
  my $x_end = 0;  
  my $pix_per_bp = $Config->transform->{'scalex'};

  return unless  $Config->get_parameter('opt_highlight') eq 'yes';

  my $fg_db = undef; ;
  my $db_type  = $self->my_config('db_type')||'funcgen';
  unless($slice->isa("Bio::EnsEMBL::Compara::AlignSlice::Slice")) {
    $fg_db = $slice->adaptor->db->get_db_adaptor($db_type);
    if(!$fg_db) {
      warn("Cannot connect to $db_type db");
      return [];
    }
  }
  
  my $reg_feat_adaptor = $fg_db->get_RegulatoryFeatureAdaptor;
  my $features = $reg_feat_adaptor->fetch_all_by_Slice($slice);
  foreach my $f (@$features){
    next unless $f->stable_id eq  $target_feature_id;
    $x = $f->start -1;
    $x_end = $f->end;
  }
   
  my $glyph = $self->Space({
    x => $x,
    y => 0,
    width => $x_end-$x+1,
    height => 0,
    colour => $colour
  });

  $self->join_tag($glyph, 'regfeat-start', 0, 0, $colour, '', 99999);
  $self->join_tag($glyph, 'regfeat-end',   1, 0, $colour, '', 99999);
  $self->push($glyph);

return;
}
1;
