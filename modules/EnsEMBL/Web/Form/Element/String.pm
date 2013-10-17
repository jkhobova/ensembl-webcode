package EnsEMBL::Web::Form::Element::String;

use strict;

use base qw(
  EnsEMBL::Web::DOM::Node::Element::Input::Text
  EnsEMBL::Web::Form::Element
);

use constant {
  VALIDATION_CLASS =>  '_string', #override in child classes
};

sub render {
  ## @overrides
  my $self = shift;
  return $self->SUPER::render(@_).$self->shortnote->render(@_);
}

sub configure {
  ## @overrides
  my ($self, $params) = @_;

  $params->{'value'}  = [ $params->{'value'}, 1 ] if exists $params->{'value'} && !$params->{'is_encoded'};

  $self->set_attribute($_, $params->{$_}) for grep exists $params->{$_}, qw(id name value size class maxlength style);
  $self->set_attribute('class', [$self->VALIDATION_CLASS, $params->{'required'} ? $self->CSS_CLASS_REQUIRED : $self->CSS_CLASS_OPTIONAL]);

  $self->$_(1) for grep $params->{$_}, qw(disabled readonly);

  $params->{'shortnote'} = '<strong title="Required field">*</strong> '.($params->{'shortnote'} || '') if $params->{'required'} && !$params->{'no_asterisk'};
  $self->{'__shortnote'} = $params->{'shortnote'} if exists $params->{'shortnote'};
}

1;