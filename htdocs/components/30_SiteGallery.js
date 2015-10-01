/*
 * Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

Ensembl.Panel.SiteGalleryHome = Ensembl.Panel.Content.extend({
  constructor: function (id, params) {
    this.base(id, params);
  },

  init: function () {
    var panel = this;
    this.base();

    /* 
    Auto-populate identifier field with hidden value, based on species and feature type selected
    */
    panel.elLk.select     = $('select[name=species]', this.el);
    panel.elLk.identifier = $('input[name=identifier]', this.el);

    // Call the update function for each scenario:

    // On page load, i.e. now!
    var type = panel.el.find('input:radio:visible').val();
    var species = panel.elLk.select.val();
    panel.updateIdentifier(panel, species, type);

    // Radio buttons
    this.elLk.radio_var   = $('input:radio[name=data_type_var]', this.el);
    this.elLk.radio_var.on({
      'change': function() {
        var type    = $(this).val();
        var species = panel.elLk.select.val();
        panel.updateIdentifier(panel, species, type);
      }
    });

    this.elLk.radio_novar = $('input:radio[name=data_type_novar]', this.el);
    this.elLk.radio_novar.on({
      'change': function() {
        var type    = $(this).val();
        var species = panel.elLk.select.val();
        panel.updateIdentifier(panel, species, type);
      }
    });

    // Species selector
    this.elLk.select.on({
      'change': function() {
        // Get species from self
        var species           = $(this).val();
        // Work out which radio button set to use
        var type = panel.el.find('input:radio:visible').val();  
        panel.updateIdentifier(panel, species, type);
      }
    });

    // Add species name at beginning of form URL e.g. /Homo_sapiens/Info/GeneGallery
    $('form.add_species_on_submit').on('submit', function () {
      var form        = this;
      var old_action  = $(form).attr('action');
      var species = $('select[name="species"] option:selected').val();
      var new_action  = '/' + species + old_action;
      form.action = new_action;
      return true;
    });
  },

  updateIdentifier: function (panel, species, type) {
    // Find the hidden input that corresponds to these options
    panel.elLk.example  = $('input[name='+species+'-'+type+']');
    var example         = panel.elLk.example.val();
    // Set the identifier field to the value of the hidden field
    panel.elLk.identifier.val(example);
  }

});
