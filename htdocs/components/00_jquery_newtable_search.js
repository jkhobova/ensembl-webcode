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

(function($) {
  $.fn.new_table_search = function(config,data) {

    function match(row,series,search,cleaner) {
      for(var i=0;i<row.length;i++) {
        var key =series[i];
        if(cleaner[key]==undefined) { continue; }
        if(!row[i] || row[i][0]===undefined) { continue; }
        var val = row[i][0];
        if(cleaner[key]) { val = cleaner[key](val); }
        if(val == undefined) { return false; }
        if(~val.toLowerCase().indexOf(search)) { return true; }
      }
      return false;
    }

    function changed($table,value) {
      var old_val = $table.data('search-value');
      if(old_val == value) { return; }
      $table.data('search-value',value);
      var view = $table.data('view');
      view.search = value;
      $table.data('view',view).trigger('view-updated');
    }

    return {
      generate: function() {
        var out = '<input class="search" placeholder="Search..."/>';
        return out;
      },
      go: function($table,$el) {
        var $box = $('.search',$el);
        var change_event = $.debounce(function($table) {
          changed($table,$box.val());
        },1000);
        $box.on("propertychange change keyup paste input",function() {
          change_event($table);
        });
      },
      position: data.position,
      pipe: function() {
        return [
          function(need,got) {
            if(!got) { return null; }
            var orig_search = need.search;
            var search = orig_search;
            var search_was_defined = need.hasOwnProperty('search');
            delete need.search;
            if(!search_was_defined) { search = ""; }
            if(!search) { return null; }
            var cleaner = {};
            var j = 0;
            var off = need.off_columns || {};
            for(var i=0;i<config.columns.length;i++) {
              if(off[config.columns[i]]) { continue; }
              var fn = config.colconf[config.columns[i]].search_clean;
              if(!fn) { fn = "html_cleaned"; }
              if(fn) { var clean = $.fn['newtable_clean_'+fn]; }
              if(clean) { cleaner[config.columns[i]] = clean; }
            }
            // XXX should search be searching columns or series?
            return {
              undo: function(manifest,grid,series,dest) {
                fabric = [];
                $.each(grid,function(i,v) {
                  if(match(grid[i],series,search.toLowerCase(),cleaner)) {
                    fabric.push(grid[i]);
                  }
                });
                if(search_was_defined) {
                  manifest.search = orig_search;
                }
                return [manifest,fabric];
              },
              all_rows: true,
              no_incr: true
            };
          }
        ];
      }
    };
  }; 

})(jQuery);