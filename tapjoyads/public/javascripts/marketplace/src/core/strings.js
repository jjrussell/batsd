(function(Tap){

  Tap.extend({
    String: {
      capitalize: function(string){
        return String(value).charAt(0).toUpperCase() + String(value).substr(1);
      },
		
      /**
       * Simple string template format method
       * @param {String} text Template with indexed place-holders which will be replaced by passed arguments
       * @param {arguments}  The string(s) to insert into the place-holders
       * @return {String} The template
       */
      format: function(string){
        var args = Tap.toArray(arguments, 1);
        return String(value).replace(Tap.RegEx.format, function(m, i){
          return args[i];
        });
      },    

      ellipsis: function(value, len, word) {
        if(value && value.length > len){
          if(word){
            var vs = value.substr(0, len - 2),
                index = Math.max(vs.lastIndexOf(' '), vs.lastIndexOf('.'), vs.lastIndexOf('!'), vs.lastIndexOf('?'));
             
            if(index !== -1 && index >= (len - 15)){
              return vs.substr(0, index) + "...";
            }
          }
          return value.substr(0, len - 3) + "...";
        }
      
        return value;
      },
    
      encodeHtml: function(value){
        var entities = {
          '&': '&amp;',
          '>': '&gt;',
          '<': '&lt;',
          '\'': '&#39;',
          '"': '&quot;'
        }, keys = [], p, regex;
      
        for(p in entities){
          keys.push(p);
        }
      
        regex = new RegExp('(' + keys.join('|') + ')', 'g');
      
        return (!value) ? value : String(value).replace(regex, function(match, capture) {
          return entities[capture];
        });
      },

      escape: function(string) {
        return String(value).replace(Tap.RegEx.escape, "\\$1");
      },

      escapeRegex: function(string) {
        return String(value).replace(Tap.RegEx.escapeRegex, "\\$1");
      },

      htmlDecode: function(value){
        var entities = {
            '&amp;': '&',
            '&gt;': '>',
            '&lt;': '<',
            '&#39;' :'\'',
            '&quot;': '"'
        }, keys = [], p, regex;

        for(p in entities){
          keys.push(p);
        }

        regex = new RegExp('(' + keys.join('|') + '|&#[0-9]{1,5};' + ')', 'g');

        return (!value) ? value : String(value).replace(regex, function(match, capture) {
          if(capture in entities){
             return entities[capture];
          }else{
            return String.fromCharCode(parseInt(capture.substr(2), 10));
          }
        });
      },
		
      reverse: function(string){
        return string.split('').reverse().join('');
      },
    
      stripHtml: function(string){
        return !string ? string : String(string).replace(Tap.RegEx.tags,  '\\$1');
      }
    }
  });
})(Tapjoy);
