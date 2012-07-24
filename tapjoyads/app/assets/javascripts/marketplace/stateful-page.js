(function (window, document) {
  "use strict";

  var stateManager = function () {
    var pageState,
        states = {},
        listenersAttached;


    function parseSearch(queryKey) {
      var rawString = window.location.search.substring(1),
          vars = rawString.split('&'),
          i, ii,
          result = {};

      for (i = 0, ii = vars.length; i < ii; i++) {
        vars[i].replace(/([\s\S]+)=([\s\S]+)/, function (pattern, key, val) {
          key && val && (result[key] = val);
        });
      }

      queryKey && (result = result[queryKey]);
      return result;
    }

    function updateState(newState) {
      var previousState = pageState;
      pageState = newState;

      if (pageState !== previousState) {
        $(window).trigger('tjm-state-change', [pageState, previousState]);
      }
    }

    function withjQuery(args, action) {
      if (!args || !action) { return; }

      args.forEach(function (val) {
        var rest = val.slice(1),
          $el = $(val[0]);

        $el[action].apply($el, rest);
      });
    }

    function leave(state) {
      if (!state) { return; }

      withjQuery(state.addClasses, 'removeClass');
      withjQuery(state.removeClasses, 'addClass');
      withjQuery(state.bindEvents, 'off');
      withjQuery(state.unbindEvents, 'on');

      state.leave && state.leave();
    }

    function enter(state) {
      if (!state) { return; }

      withjQuery(state.addClasses, 'addClass');
      withjQuery(state.removeClasses, 'removeClass');
      withjQuery(state.bindEvents, 'on');
      withjQuery(state.unbindEvents, 'off');

      state.enter && state.enter();
    }

    function attachListeners() {
      $(window).on('tjm-state-change', function (ev, currState, prevState) {
        var current = states[currState],
            previous = states[prevState];

        leave(previous);
        enter(current);
      });

      ['next', 'previous'].forEach(function (direction) {
        $('.js-' + direction + '-state').on('click', function () {
          !$(this).attr('disabled') && traverse(direction);
        });
      });

      $('.js-set-state').on('click', function () {
        var hrefVal = $(this).attr('href');
        hrefVal.charAt(0) === "#" && (hrefVal = hrefVal.slice(1));

        updateState(hrefVal);
        return false;
      });
      listenersAttached = true;
    }

    function traverse(direction) {
      var newState = states[pageState] && states[pageState][direction];
      newState && updateState(newState);
    }

    // setup listeners, check for current state in address bar
    function begin(initialState) {
      var s;

      !listenersAttached && attachListeners();

      s = parseSearch('state') || initialState;
      updateState(s);
    }

    return {
      states: states,
      getState: function () {
        return pageState;
      },
      setState: function (newState) {
        updateState(newState);
      },
      next: function () {
        traverse('next');
      },
      previous: function () {
        traverse('previous');
      },
      add: function (name, newState, previous, next) {
        next && (newState.next = next);
        previous && (newState.previous = previous);
        states[name] = newState;
        return this;
      },
      begin: begin,
      fn: {}
    };
  };

  window.tjStates = window.stateful = stateManager();
}(this.window, this.document));
