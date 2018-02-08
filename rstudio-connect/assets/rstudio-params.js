window.onload = function () {

  var rstudio = __setupRstudioParams();
  var globalConnect = __connect;
  var shinyVersion = rstudio.shinyVersion(globalConnect);

  // the shiny:idle always fires when the app has finished loading. So this is good enough to
  // remove the spinner. However, the form may not be visually ready (hence the `shiny:visualchange`
  // listener below
  var firstIdle = false;

  $(window.document).on('shiny:idle', function() {
    if (!firstIdle) {
      firstIdle = true;
      window.parent.postMessage({type: 'customshiny:ready'}, '*');
    }
  });

  // this fires when each individual input has finished rendering
  $('body > div').on('shiny:visualchange', function() {
    window.parent.postMessage({type: 'customshiny:resize'}, '*');
  });

  $(window.document).on('shiny:inputchanged', rstudio.onInputChange(shinyVersion));

  // file upload is a special case. it doesn't fire the shiny:inputchanged event.
  // in this case we use shiny:bound to attach change listeners when it's ready. FYI, unfortunately,
  // shiny:bound can't be used for everything because radio buttons are a special case and it also doesn't
  // fire for the calendar input.
  $(window.document).on('shiny:bound', function(evt) {

      if (evt.target.nodeName.toLowerCase() === 'input' && evt.target.type === 'file') {

        $(evt.target).on('input', function (evt) {
          window.parent.postMessage(rstudio.onChangeMessage(evt), '*');
        });
        $(evt.target).on('change', function (evt) {
          window.parent.postMessage(rstudio.onChangeMessage(evt), '*');
        });
      }
  });

  // resize the form whenever it visually changes. Unfortunately, `shiny:visualchange` fires only when the
  // inputs are first rendered.
  $(document).keydown(function() {
    window.parent.postMessage({type: 'customshiny:resize'}, '*');
  });
  $(document).click(function() {
    window.parent.postMessage({type: 'customshiny:resize'}, '*');
  });

  // kill default shiny keyup listener injected by shiny
  $(document).off('keyup');
  $(document).keyup(function(e) {
    if (e.which == 13) { e.preventDefault() } // enter
    if (e.which == 27) { e.preventDefault() } // esc
  });

  // receive messages from connect
  window.addEventListener('message', function(msg) {
    if (msg.data.type === 'customshiny:save') {
      $('#save').trigger('click');
    } else if (msg.data.type === 'customshiny:cancel') {
      $('#cancel').trigger('click');
    }
  });
};


function __setupRstudioParams() {

  /**
   * Supports semversioning in the form [0.999].[0.999].[0..999]. The patch version is actually optional.
   *
   * @param {{shiny:string} globalConnectObj
   * @returns {integer} in the form MMMIIIPPP, where MMM is the major version, III is the minor version,
   * and PPP is the patch version. For example, 1.24.321 returns 1,024,321 and 16.240.321 returns 16,240,321.
   */
  function shinyVersion(globalConnectObj) {
    var shinyVersion = globalConnectObj.shiny;
    var versionInfo = shinyVersion.split('.');
    var major = +versionInfo[0];
    var minor = +versionInfo[1];
    var patch = 0;
    // Actually, shiny *mostly* follows semversion. If no patch, then default to 0.
    // We support pre-release version by ignoring it.
    if (versionInfo.length >= 3) {
      patch = +versionInfo[2];
    }
    var version = major*1000000 + minor*1000 + patch;
    return version;
  }


  /**
   * shiny:inputchanged doesn't work for us because it fires *anytime* the input changed, including when
   * the server sets the initial values. Therefore we debounce these events---we ignore the first
   * events for each input since these correspond to the form initialization. FYI, we also tried using
   * shiny:idle in combination with shiny:inputchanged; however, that fired too early.
   *
   * The number of events we ignore depends on the shiny version.
   *
   * Note that inputs with NULL values or time inputs are a special case. See #isInitialDefaultOnchangeEvent.
   * @param {number} shinyVersion
   */
  function onInputChange(shinyVersion) {

    var inputChangedInvokeCount = {};
    /**
     * corresponds to version "1.0.1". See #shinyVersion above
     * @type {number}
     */
    var shinyLegacyVersion = 1000001;
    var legacyHandler = function pre102onInputChange(evt) {
      if (!isShinyHiddenInput(evt)) {
        var inputId = evt.name;
        /**
         * The result of painstakingly stepping through each event type reveals that you need to ignore the
         * first 3 events
         * @type {number}
         */
        var ignoreCount = 3;

        inputChangedInvokeCount[inputId] = (inputChangedInvokeCount[inputId] || 0) + 1;

        if (inputChangedInvokeCount[inputId] >= ignoreCount
          && !isInitialDefaultOnchangeEvent(shinyVersion)(inputChangedInvokeCount, evt)) {
          window.parent.postMessage(onChangeMessage(evt), '*');
        }
      }
    };
    var post101Handler = function post102onInputChange(evt) {
      if (!isShinyHiddenInput(evt)) {
        var inputId = evt.name;
        /**
         * The result of painstakingly stepping through each event type reveals that you need to ignore the
         * first 2 events
         * @type {number}
         */
        var ignoreCount = 2;

        inputChangedInvokeCount[inputId] = (inputChangedInvokeCount[inputId] || 0) + 1;

        if (inputChangedInvokeCount[inputId] >= ignoreCount
          && !isInitialDefaultOnchangeEvent(shinyVersion)(inputChangedInvokeCount, evt)) {
          window.parent.postMessage(onChangeMessage(evt), '*');
        }
      }
    };
    return function onInputChangeHandler(evt) {
      return shinyVersion < shinyLegacyVersion ? legacyHandler(evt) : post101Handler(evt)
    };
  }


  function isShinyHiddenInput(evt) {
    return /^\.clientdata_output_.*_hidden$/.test(evt.name) || evt.name === '.clientdata_pixelratio'
  }


  /**
   * It's a "default" dropdown when the id is of the form `select_foo`.
   *
   * @param evt
   * @returns {boolean}
   */
  function isDefaultDropdown(evt) {
    var id = evt.name;
    var isDropdown = /^select_.+$/.test(id);

    return isDropdown
  }


  /**
   * Text input with NULL values (or time inputs with DEFAULT values) create a "fake" dropdown (for lack of
   * better words) with ID of the form `select_foo` (where `foo` is the ID of the original input). These
   * fake dropdowns fire two extra `shiny:onchange` events with a value of "default" and then one extra
   * `shiny:onchange` when the user selects a custom value with a value of "custom".
   *
   * This method checks for the above case.
   *
   * Note an edge case exists when these conditions are satisfied:
   * 1.  an input widget with id of the form `select_foo` actually exists
   * 2.  the first three changes to this input are to the values "default" or "custom".
   * For this edge case, the onChange event will not fire.
   *
   * @param {number} shinyVersion
   * @param {Map} inputChangedInvokeCount
   * @param {Event} evt
   * @returns {boolean}
   */
  function isInitialDefaultOnchangeEvent(shinyVersion) {
    /**
     * corresponds to version "1.0.1". See #shinyVersion above
     * @type {number}
     */
    var shinyLegacyVersion = 1000001;
    var legacyHandler = function(inputChangedInvokeCount, evt) {
      /**
       * For default dropdown events, we ignore the first 4 events.
       * @type {number}
       */
      var ignoreCount = 4;
      return inputChangedInvokeCount[evt.name] <= ignoreCount &&
        isDefaultDropdown(evt) &&
        evt.value === 'default';
    };
    var post101Handler = function(inputChangedInvokeCount, evt) {
      /**
       * For default dropdown events, we ignore the first 3 events.
       * @type {number}
       */
      var ignoreCount = 3;
      return inputChangedInvokeCount[evt.name] <= ignoreCount &&
        isDefaultDropdown(evt) &&
        evt.value === 'default';
    };
    return function isInitialDefaultOnchangeEventHandler(inputChangedInvokeCount, evt) {
      return shinyVersion < shinyLegacyVersion
        ? legacyHandler(inputChangedInvokeCount, evt)
        : post101Handler(inputChangedInvokeCount, evt);
    };
  }


  function onChangeMessage(evt) {
    return {
      type: 'customshiny:onchange',
      evt: {id: evt.target.id}
    };
  }



  return {
    shinyVersion: shinyVersion,
    onInputChange: onInputChange,
    onChangeMessage: onChangeMessage,
  };
}
