package Bio::EnsEMBL::GlyphSet::Vgenes;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Sanger::Graphics::Glyph::Rect;
use Sanger::Graphics::Glyph::Poly;
use Sanger::Graphics::Glyph::Text;
use Sanger::Graphics::Glyph::Line;

use Data::Dumper;

sub init_label {
    my ($self) = @_;
    my $Config = $self->{'config'};	
    $self->label(new Sanger::Graphics::Glyph::Text({
	        'text'      => 'Known Genes',
		'font'      => 'Small',
		'colour'	=> $Config->get('Vgenes','col_known'),
		'absolutey' => 1,
    }));
    $self->label2(new Sanger::Graphics::Glyph::Text({
		'text'      => 'Genes',
		'font'      => 'Small',
		'colour'	=> $Config->get('Vgenes','col_genes'),		
		'absolutey' => 1,
    }));
}

sub _init {
    my ($self) = @_;
    my $Config = $self->{'config'};
    my $chr    = $self->{'extras'}->{'chr'} || $self->{'container'}->{'chr'};
   	my $genes_col = $Config->get( 'Vgenes','col_genes' );
   	my $known_col = $Config->get( 'Vgenes','col_known' );
	my $chr_slice = $self->{'container'}->{'sa'}->fetch_by_region('chromosome', $chr);	
    my $known_genes = $self->{'container'}->{'da'}->fetch_Featureset_by_Slice($chr_slice,'kngene', 150, 1);
    my $genes = $self->{'container'}->{'da'}->fetch_Featureset_by_Slice($chr_slice,'gene', 150, 1);

	my $v_offset    = $Config->container_width() - ($chr_slice->length() || 1);

#    my $v_offset    = $Config->container_width() - ($self->{'container'}->{'ca'}->fetch_by_chr_name($chr)->length() || 1);

    return unless $known_genes->size() && $genes->size();

   	$genes->scale_to_fit( $Config->get( 'Vgenes', 'width' ) );
	$genes->stretch(0);
	my $Hscale_factor = $known_genes->max_value / $genes->max_value;
   	$known_genes->scale_to_fit( $Config->get( 'Vgenes', 'width' ) * $Hscale_factor );	
	$known_genes->stretch(0);
	my @genes = @{$genes->get_all_binvalues()};
	my @known_genes = @{$known_genes->get_all_binvalues()};	

    foreach (@genes){
       my $known_gene = shift @known_genes;	
       my $g_x = new Sanger::Graphics::Glyph::Rect({
			'x'      => $v_offset + $known_gene->start,
			'y'      => 0,
			'width'  => $known_gene->end - $known_gene->start,
			'height' => $known_gene->scaledvalue,
			'colour' => $known_col,
			'absolutey' => 1,
		});
	    $self->push($g_x);
#		warn " Known_gene: \033[31m ".Dumper($g_x)."\033[0m \n ";
		$g_x = new Sanger::Graphics::Glyph::Rect({
			'x'      => $v_offset + $_->start,
			'y'      => 0,
			'width'  => $_->end - $_->start,
			'height' => $_->scaledvalue,
			'bordercolour' => $genes_col,
			'absolutey' => 1,
			'href'   => "/@{[$self->{container}{_config_file_name_}]}/contigview?chr=$chr&vc_start=$_->start&vc_end=$_->end"
		});
#		warn "Unknown_Gene\033[31m ".Dumper($g_x)."\033[0m \n ";
	    $self->push($g_x);
	}
	
}

1;
