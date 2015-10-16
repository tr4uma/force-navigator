'use strict';

var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var _createClass = (function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ('value' in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; })();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError('Cannot call a class as a function'); } }

var ForceNavigatorUI = (function () {
  function ForceNavigatorUI() {
    _classCallCheck(this, ForceNavigatorUI);

    var div = document.createElement('div');
    div.setAttribute('id', 'sfnav_search_box');

    div.innerHTML = '\n      <div class="sfnav_wrapper">\n        <input type="text" id="sfnav_quickSearch" autocomplete="off">\n          <img id="sfnav_loader" />\n          <img id="sfnav_logo" />\n      </div>\n      <div class="sfnav_shadow" id="sfnav_shadow"/>\n      ';
    document.body.appendChild(div);
    this.el = div;
    this.aplete = new window.Awesomplete(document.getElementById('sfnav_quickSearch'));
  }

  _createClass(ForceNavigatorUI, [{
    key: 'setResults',
    value: function setResults() {
      this.aplete.list = results;
    }
  }]);

  return ForceNavigatorUI;
})();

var ForceCommands = (function () {
  function ForceCommands() {
    _classCallCheck(this, ForceCommands);

    this.SFAPI_VERSION = 'v34.0';
    this.sid = this.getCookie('sid');
    this.clientId = this.sid.split('!')[0];
    this.hash = this.clientId + '!' + this.sid.substring(this.sid.length - 10, this.sid.length);
    this.serverUrl = this.getServerUrl();
    this.getCommands();
  }

  _createClass(ForceCommands, [{
    key: 'getCommands',
    value: function getCommands(cb) {
      var _this = this;

      chrome.extension.sendMessage({ action: 'Get Commands', 'key': this.hash }, function (cmds) {
        if (cmds == null || cmds.length == 0) {
          _this.load(cb);
        } else {
          cb(cmds);
        }
      });
    }
  }, {
    key: 'store',
    value: function store(action, payload) {
      var req = {
        action: action,
        key: this.hash,
        payload: payload
      };

      chrome.extension.sendMessage(req, function (resp) {});
    }
  }, {
    key: 'load',
    value: function load(cb) {
      var _this2 = this;

      this.getSetupTree(function (setupCmds) {
        var allCmds = _extends({}, cmds, setupCmds);
        _this2.store('Store Commands', allCmds);
        getCustomObjectTree(function (objCmds) {
          _this2.store('Store Commands', _extends({}, allCmds, objCmds));
        });
      });
      this.httpGet(this.serverUrl + '/services/data/' + this.SFAPI_VERSION + '/sobjects/', function (response) {
        var cmds = parseMeta(response.target.responseText);
        cmds['Refresh Metadata'] = {};
        cmds['Setup'] = {};
        _this2.store('Store Commands', allCmds);
      });
    }
  }, {
    key: 'parseCustomObjectTree',
    value: function parseCustomObjectTree(html) {
      var doc = document.createElement('html');
      doc.innerHtml = html;
      var cmds = {};
      document.querySelectorAll('th a').each(function (el) {
        cmds['Setup > Custom Object > ' + this.text] = { url: this.href, key: this.text };
      });

      this.store('Store Commands', cmds);
      return cmds;
    }
  }, {
    key: 'getCustomObjects',
    value: function getCustomObjects(cb) {
      var _this3 = this;

      var theurl = this.serverInstance + '/p/setup/custent/CustomObjectsPage';
      this.httpGet(theurl, 'document', function (response) {
        cb(_this3.parseSetupTree(response));
      });
    }
  }, {
    key: 'getSetupTree',
    value: function getSetupTree(cb) {
      var _this4 = this;

      var theurl = this.serverInstance + '/ui/setup/Setup';
      this.httpGet(theurl, 'document', function (response) {
        cb(_this4.parseSetupTree(response));
      });
    }
  }, {
    key: 'parseSetupTree',
    value: function parseSetupTree() {
      var textLeafSelector = '.setupLeaf > a[id*="_font"]';
      var all = html.querySelectorAll(textLeafSelector);
      var strName = undefined;
      var as = undefined;
      var strNameMain = undefined;
      var cmds = {};
      Array.prototype.map.call(all, function (item) {
        var hasTopParent = false,
            hasParent = false;
        var parent = undefined,
            topParent = undefined;
        var parentEl = undefined,
            topParentEl = undefined;

        if (item.parentElement != null && item.parentElement.parentElement != null && item.parentElement.parentElement.parentElement != null && item.parentElement.parentElement.parentElement.className.indexOf('parent') !== -1) {

          hasParent = true;
          parentEl = item.parentElement.parentElement.parentElement;
          parent = parentEl.querySelector('.setupFolder').innerText;
        }
        if (hasParent && parentEl.parentElement != null && parentEl.parentElement.parentElement != null && parentEl.parentElement.parentElement.className.indexOf('parent') !== -1) {
          hasTopParent = true;
          topParentEl = parentEl.parentElement.parentElement;
          topParent = topParentEl.querySelector('.setupFolder').innerText;
        }

        strNameMain = 'Setup > ' + (hasTopParent ? topParent + ' > ' : '');
        strNameMain += hasParent ? parent + ' > ' : '';

        strName = strNameMain + item.innerText;

        if (cmds[strName] == null) cmds[strName] = { url: item.href, key: strName };
      });
    }
  }, {
    key: 'parseMeta',
    value: function parseMeta(response) {

      var metadata = JSON.parse(response);

      var isLightning = location.origin.indexOf('lightning') != -1;
      var cmds = {};

      for (var i = 0; i < metadata.sobjects.length; i++) {
        if (metadata.sobjects[i].keyPrefix != null) {
          var mRecord = {};
          mRecord.label = metadata.sobjects[i].label;
          mRecord.labelPlural = metadata.sobjects[i].labelPlural;
          mRecord.keyPrefix = metadata.sobjects[i].keyPrefix;
          mRecord.urls = metadata.sobjects[i].urls;

          var act = {};
          act.key = metadata.sobjects[i].name;
          act.keyPrefix = metadata.sobjects[i].keyPrefix;
          act.url = serverInstance + '/' + metadata.sobjects[i].keyPrefix;
          if (isLightning) act.url = location.origin + location.pathname + '#/sObject/' + metadata.sobjects[i].keyPrefix + '/home';

          cmds['List ' + mRecord.labelPlural] = act;
          act = {};
          act.key = metadata.sobjects[i].name;
          act.keyPrefix = metadata.sobjects[i].keyPrefix;
          act.url = serverInstance + '/' + metadata.sobjects[i].keyPrefix;
          act.url += '/e';
          if (isLightning) act.url = location.origin + location.pathname + '#/sObject/' + metadata.sobjects[i].keyPrefix + '/new';

          cmds['New ' + mRecord.label] = act;
        }
      }
      return cmds;
    }
  }, {
    key: 'httpGet',
    value: function httpGet(url, responseType, callback) {
      var req = new XMLHttpRequest();
      req.open("GET", url, true);
      req.setRequestHeader("Authorization", 'Bearer ' + this.sid);
      req.onload = function (response) {
        callback(response);
      };
      if (responseType) req.responseType = responseType;
      req.send();
    }
  }, {
    key: 'getCookie',
    value: function getCookie(c_name) {
      var i,
          x,
          y,
          ARRcookies = document.cookie.split(";");
      for (i = 0; i < ARRcookies.length; i++) {
        x = ARRcookies[i].substr(0, ARRcookies[i].indexOf("="));
        y = ARRcookies[i].substr(ARRcookies[i].indexOf("=") + 1);
        x = x.replace(/^\s+|\s+$/g, "");
        if (x == c_name) return unescape(y);
      }
    }
  }, {
    key: 'getServerUrl',
    value: function getServerUrl() {
      var url = location.origin + "";
      var urlParseArray = url.split(".");

      if (url.indexOf("salesforce") != -1) {
        return url.substring(0, url.indexOf("salesforce")) + "salesforce.com";
      }

      if (url.indexOf("cloudforce") != -1) {
        return url.substring(0, url.indexOf("cloudforce")) + "cloudforce.com";
      }

      if (url.indexOf("visual.force") != -1) {
        return 'https://' + urlParseArray[1] + '.salesforce.com';
      }

      if (url.indexOf("lightning.force.com") != -1) {
        return urlParseArray[0] + '.salesforce.com';
      }
    }
  }]);

  return ForceCommands;
})();

var App = function App() {
  _classCallCheck(this, App);

  this.ui = new ForceNavigatorUI();
};
