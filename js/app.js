(function() {
  var data;

  requirejs.config({
    baseUrl: 'js',
    paths: {}
  });

  data = ['require', 'core/db', 'assets/colors', 'core/render'];

  requirejs(data, function(require, db, colors, render) {

    /*
    	data = [{
    		code: 'MB103'
    		name: 'Matematika a štatistika'
    
    		lecture:
    			room: 'D1'
    			teacher: { name: 'Antonio Banderas', link: '#' }
    			code: 'MB103'
    			name: 'Matematika a štatistika'
    			day: 1
    			time: { from: 700, to: 830 }
    
    		labs: [{
    
    			subject: 'MB103'
    			code: 'MB103/02'
    			room: 'G101'
    			teacher: { name: 'Antom Mráz', link: '#' }
    			note: 'Musíš obrať zemiaky!'
    			day: 2
    			time: { from: 1000, to: 1250 }
    		},
    		{
    			subject: 'MB103'
    			code: 'MB103/03'
    			room: 'G101'
    			teacher: { name: 'Antom Mráz', link: '#' }
    			day: 3
    			time: { from: 1000, to: 1350 }
    		}]
    	},
    	{
    		code: 'IB000'
    		name: 'Zemepán'
    		lecture:
    			code: 'IB000'
    			name: 'Zemepán'
    			room: 'D2'
    			teacher: { name: 'Antonio Banderas', link: '#' }
    			day: 0
    			time: { from: 700, to: 830 }
    
    		labs: [{
    
    			subject: 'IB000'
    			code: 'IB000/02'
    			room: 'C201'
    			teacher: { name: 'Marek Kohút', link: '#' }
    			day: 0
    			time: { from: 800, to: 1150 }
    		},
    		{
    			subject: 'IB000'
    			code: 'IB000/03'
    			room: 'B110'
    			teacher: { name: 'Martin Zuro', link: '#' }
    			day: 3
    			time: { from: 1000, to: 1350 }
    		}]
    	}]
     */
    var insert;
    insert = function(data) {
      var subject, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        subject = data[_i];
        if (!subject.color) {
          subject.color = colors[Math.floor(Math.random() * (colors.length - 0))];
        }
        if (!subject.color) {
          subject.locked = false;
        }
        _results.push(db.use('subjects').create(subject));
      }
      return _results;
    };

    /*
    	update = (data)->
    
    		seconds = new Date().getTime() / 1000
    
    		subjects = db.use( 'subjects' ).find ( s )-> s.timestamp < ( new Date().getTime() / 1000 ) - 3600  # Nájde všetky predmety, ktoré sa za poslednú hodinu neaktualizovali
    
    
    		for subject in subjects
    
    			$.post 'index.php', { action: 'read', classes:  }, ( response )->
     */
    if (window.show_schedule) {
      render.classes();
      render.schedule();
    }
    $(document).on('click', '.lock', function() {
      var code, locked, parent, seminar, subject;
      if (window.preview) {
        alert('Najskôr vypni finálne zobrazenie!');
        return;
      }
      parent = $(this).parent();
      code = $(parent).attr('data-class');
      subject = db.use('subjects').findOne(function(s) {
        return s.code === $.trim(code);
      });
      seminar = subject.labs[subject.labs.indexOf((subject.labs.filter(function(l) {
        return l.code === $.trim($(parent).attr('data-seminar'));
      }))[0])];
      if (!seminar.locked) {
        seminar.locked = false;
      }
      locked = seminar.locked;
      seminar.locked = !locked;
      subject.locked = !locked;
      subject.save();
      return $('[data-class="' + code + '"]').each(function() {
        if (this !== parent[0] && !locked) {
          $(this).slideUp();
        }
        if (this !== parent[0] && locked) {
          return $(this).slideDown();
        }
      });
    });
    $(document).on('click', '.remove', function() {
      var code, subject;
      code = $(this).attr('data-code');
      subject = db.use('subjects').findOne(function(s) {
        return s.code === code;
      });
      subject.remove();
      render.classes();
      return render.schedule();
    });
    $(document).on('click', '.change-color', function() {
      var code, subject;
      code = $(this).attr('data-code');
      subject = db.use('subjects').findOne(function(s) {
        return s.code === code;
      });
      subject.color = colors[Math.floor(Math.random() * (colors.length - 0))];
      subject.save();
      render.classes();
      return render.schedule();
    });
    $(document).on('click', '#create', function() {
      var classes, code, codes, exists, new_classes, _i, _len, _this;
      $(this).val('Loading ...');
      $(this).attr('disabled', '1');
      _this = this;
      classes = $('#class_input').val();
      new_classes = [];
      $('#class_input').val('');
      if (!classes) {
        $(_this).val('Odoslať');
        $(_this).removeAttr('disabled');
        return;
      }
      codes = classes.split(',');
      for (_i = 0, _len = codes.length; _i < _len; _i++) {
        code = codes[_i];
        code = code.split(':');
        if (code.length === 1) {
          render.error(['Predmet [' + code[0] + '] zadaný v nesprávnom tvare!']);
          continue;
        }
        exists = db.use('subjects').findOne(function(s) {
          return s.code === $.trim(code[1]);
        });
        if (!exists) {
          new_classes.push($.trim(code.join(':')));
        }
      }
      if (new_classes.length > 0) {
        return $.post('index.php', {
          action: 'read',
          classes: new_classes.join(',')
        }, function(response) {
          console.log('zemiaky');
          console.log(response);
          $(_this).val('Odoslať');
          $(_this).removeAttr('disabled');
          response = JSON.parse(response);
          insert(response.classes);
          render.schedule();
          render.classes();
          return render.error(response.errors);
        });
      } else {
        $(_this).val('Odoslať');
        return $(_this).removeAttr('disabled');
      }
    });
    $(document).on('click', '#signme', function() {
      var person, _this;
      person = db.use('person').findOne();
      if (person) {
        person = person.uco;
      }
      $(this).val('Loading ...');
      $(this).attr('disabled', '1');
      _this = this;
      return $.post('index.php', {
        action: 'sign_in',
        uco: $('#uco').val(),
        password: $('#password').val(),
        person: person
      }, function(response) {
        var error, _i, _len, _ref, _results;
        console.log(response);
        $(_this).val('Odoslať');
        $(_this).removeAttr('disabled');
        db.use('person').drop();
        db.use('person').create({
          uco: $('#uco').val()
        });
        response = JSON.parse(response);
        if (response.classes && response.classes.length > 0) {
          db.use('subjects').drop();
        }
        if (response.classes) {
          db.use('subjects').drop();
          insert(response.classes);
        }
        if (response.classes || response.log_me_in) {
          document.location.reload();
        }
        if (response.error) {
          _ref = response.error;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            error = _ref[_i];
            _results.push(alert(error));
          }
          return _results;
        }
      });
    });
    $(document).on('click', '#sign_out', function() {
      return $.post('index.php', {
        action: 'sign_out'
      }, function(response) {
        return document.location.reload();
      });
    });
    $(document).on('click', '#final-view', function() {
      if (!window.preview) {
        window.preview = false;
      }
      window.preview = !window.preview;
      return render.schedule();
    });
    return $(document).on('click', '#errors .close', function() {
      return $(this).parent().remove();
    });
  });

}).call(this);
