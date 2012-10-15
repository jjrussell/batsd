$(function($) {
  var dailyBudget = function() {
    var $t = this;

    $t.offer_bid = $('#offer_bid');
    $t.fields    = $('#daily_budget_fields');
    $t.payment   = $('#offer_payment');
    $t.installs  = $('#offer_daily_budget');
    $t.budget    = $('#estimated_budget');

    $t.ro_installs = $('#offer_daily_budget_read_only');
    $t.ro_budget   = $('#estimated_budget_read_only');

    $t.toggle_on  = $('#daily_budget_toggle_on');
    $t.toggle_off = $('#daily_budget_toggle_off');

    $t.cap_installs = $('#offer_daily_cap_type_installs');
    $t.cap_budget   = $('#offer_daily_cap_type_budget');

    $t.attachEvents();

    if ($t.isBudgetOn()) {
      $t.installs.val(addCommaSeparators($t.getInstalls()));
      $t.updateBudget();
    }

    $t.clear();
  };

  $.extend(dailyBudget.prototype, {
    check: function() {
      var $t = this;
      if (false === $t.valid()) {
        $t.installs.val('1');
        alert('Daily install limit must be at least 1. To disable the campaign, please uncheck the box labeled "Enable Installs".');
        return false;
      }
      return true;
    },
    valid: function() {
      return (!this.isBudgetOn() || (this.isBudgetOn() && this.getInstalls() > 0));
    },
    isBudgetOn: function() {
      return this.toggle_on.is(':checked');
    },

    update: function() {
      var $t = this;
      if($t.cap_budget.is(':checked'))
        $t.updateInstalls();
      else
        $t.updateBudget();
    },
    updateInstalls: function() {
      var $t = this, installs;

      installs = $t.calculateInstalls();
      $t.setInstalls(installs);
    },
    updateBudget: function() {
      var $t = this;
      $t.setBudget($t.calculateBudget());
    },

    getInstalls: function() {
      return stringToNumber(this.installs.val());
    },
    setInstalls: function(value) {
      var $t = this;
      $t.installs.val(addCommaSeparators(value));
      $t.ro_installs.html(addCommaSeparators(value));
    },
    getPayment: function() {
      return stringToNumber(this.payment.val());
    },
    getBudget: function() {
      return stringToNumber(this.budget.val());
    },
    setBudget: function(value) {
      var $t = this;
      $t.budget.val(numberToCurrency(value));
      $t.ro_budget.html(numberToCurrency(value));
    },

    calculateInstalls: function() {
      return Math.floor(this.getBudget() / this.getPayment());
    },
    calculateBudget: function() {
      return this.getPayment() * this.getInstalls();
    },

    attachEvents: function() {
      var $t = this;

      $t.offer_bid.bind('keypress', function(e) {
        if (e.keyCode === 13) return false;
      });

      $t.installs.bind('change', function(e) {
        var installs = Math.floor($t.getInstalls());
        $t.setInstalls(installs);
        $t.updateBudget();
      });
      $t.budget.bind('change', function(e) {
        var budget = $t.getBudget();
        $t.setBudget(budget);
        $t.updateInstalls();

        if (false === $t.check()) {
          $t.installs.trigger('change');
        }
      });

      $t.toggle_on.bind('click', function() {
        $t.enable();
      });
      $t.toggle_off.bind('click', function() {
        $t.disable();
      });

      $t.cap_installs.bind('click', function() {
        $t.ro_installs.hide();
        $t.installs.fadeIn();
        $t.budget.hide();
        $t.ro_budget.fadeIn();
      });
      $t.cap_budget.bind('click', function() {
        $t.installs.hide();
        $t.ro_installs.fadeIn();
        $t.ro_budget.hide();
        $t.budget.fadeIn();
      });
    },

    enable: function() {
      this.fields.slideDown();
      this.clear();
    },
    disable: function() {
      this.fields.slideUp();
      this.clear();
    },
    clear: function() {
      var $t = this;

      if ($t.getInstalls() == 0) {
        $t.installs.val('');
        $t.ro_installs.html('');
        $t.budget.val('');
        $t.ro_budget.html('');
      }
    }
  });

  window.dailyBudget = new dailyBudget();
});
