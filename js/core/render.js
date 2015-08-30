(function() {
  define(['require', 'core/db'], function(require, db) {
    return {
      day_template: Handlebars.compile($('#day-template').length === 0 ? '' : $('#day-template').html()),
      class_template: Handlebars.compile($('#class-template').length === 0 ? '' : $('#class-template').html()),
      error_template: Handlebars.compile($('#error-template').length === 0 ? '' : $('#error-template').html()),
      schedule: function() {
        var Line, Subject, day, days, handlebars_data, i, lab, row, subject, subjects, _i, _j, _k, _l, _len, _len1, _len2, _m, _ref;
        Line = db.use('lines');
        Subject = db.use('subjects');
        handlebars_data = {
          days: []
        };
        days = ['Po', 'Ut', 'St', 'Št', 'Pi'];
        for (i = _i = 1; _i <= 5; i = ++_i) {
          handlebars_data.days[i - 1] = {
            name: days[i - 1],
            line: []
          };
        }
        Line.drop();
        subjects = Subject.find();
        for (_j = 0, _len = subjects.length; _j < _len; _j++) {
          subject = subjects[_j];
          this._insert_into_schedule.call(this, subject.lecture, subject, {
            lecture: true
          });
          _ref = subject.labs;
          for (_k = 0, _len1 = _ref.length; _k < _len1; _k++) {
            lab = _ref[_k];
            this._insert_into_schedule.call(this, lab, subject);
          }
        }
        for (day = _l = 0; _l <= 4; day = ++_l) {
          row = Line.find(function(l) {
            return l.day === day;
          });
          if (!row) {
            continue;
          }
          row = row.sort(function(a, b) {
            return b.line - a.line;
          });
          for (_m = 0, _len2 = row.length; _m < _len2; _m++) {
            subject = row[_m];
            if (handlebars_data.days[day] == null) {
              handlebars_data.days[day] = {};
            }
            if (!handlebars_data.days[day]['line']) {
              handlebars_data.days[day]['line'] = [];
            }
            if (handlebars_data.days[day]['line'][subject.line] == null) {
              handlebars_data.days[day]['line'][subject.line] = [];
            }
            handlebars_data.days[day]['line'][subject.line].push(subject);
          }
        }
        return $('#schedule #days').html(this.day_template(handlebars_data));
      },
      _insert_into_schedule: function(data, subject, extend) {
        var Line, line, line_count, _i;
        console.log(data, subject, extend);
        if (extend == null) {
          extend = {};
        }
        if ((data == null) || !data.time || !data.time.from || !data.time.to) {
          return;
        }
        if (subject.locked && !data.locked && window.preview && !extend.lecture) {
          return;
        }
        if (subject.locked && !data.locked && !extend.lecture) {
          extend["class"] = 'hide-no-bootstrap';
        }
        Line = db.use('lines');
        for (line_count = _i = 0; _i <= 30; line_count = ++_i) {
          line = Line.findOne(function(l) {
            return l.day === data.day && l.line === line_count && ((parseInt(l.time.from) <= parseInt(data.time.from) && parseInt(l.time.to) > parseInt(data.time.from)) || (parseInt(l.time.from) < parseInt(data.time.to) && parseInt(l.time.to) >= parseInt(data.time.to)) || (parseInt(l.time.from) >= parseInt(data.time.from) && parseInt(l.time.to) <= parseInt(data.time.to)));
          });
          if (!line) {
            break;
          }
        }
        return Line.create($.extend({}, data, {
          line: line_count,
          color: subject.color,
          left: (parseInt(data.time.from) - 700) / 15,
          width: (parseInt(data.time.to) - parseInt(data.time.from)) / 15
        }, extend));
      },
      classes: function() {
        var Subject;
        Subject = db.use('subjects');
        return $('#classes').html(this.class_template({
          "class": Subject.find()
        }));
      },
      error: function(errors) {
        var error, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = errors.length; _i < _len; _i++) {
          error = errors[_i];
          _results.push($('#errors').append(this.error_template({
            message: error
          })));
        }
        return _results;
      }
    };
  });

}).call(this);
