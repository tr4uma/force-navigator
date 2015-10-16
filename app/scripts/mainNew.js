
class ForceNavigatorUI {

  constructor () {
    let div = document.createElement('div');
    div.setAttribute('id', 'sfnav_search_box')

    div.innerHTML = `
      <div class="sfnav_wrapper">
        <input type="text" id="sfnav_quickSearch" autocomplete="off">
          <img id="sfnav_loader" />
          <img id="sfnav_logo" />
      </div>
      <div class="sfnav_shadow" id="sfnav_shadow"/>
      `
    document.body.appendChild(div)
    this.el = div
    this.aplete = new window.Awesomplete(document.getElementById('sfnav_quickSearch'))
  }

  setResults () {
    this.aplete.list = results
  }

}



class ForceCommands {

  constructor () {
    this.SFAPI_VERSION = 'v34.0'
    this.sid = this.getCookie('sid')
    this.clientId = this.sid.split('!')[0]
    this.hash = this.clientId + '!' + this.sid.substring(this.sid.length - 10, this.sid.length)
    this.serverUrl = this.getServerUrl()
    this.getCommands()
  }

  getCommands(cb) {
    chrome.extension.sendMessage({action:'Get Commands', 'key': this.hash}, (cmds) => {
      if(cmds == null || cmds.length == 0) {
        this.load(cb)
      } else {
        cb(cmds)
      }
    })
  }

  store (action, payload) {
    var req = {
      action: action,
      key: this.hash,
      payload: payload
    }

    chrome.extension.sendMessage(req, (resp) => {});
  }

  load(cb) {


this.getSetupTree((setupCmds) => {
        let allCmds = { ...cmds, ...setupCmds }
        this.store('Store Commands', allCmds)
        getCustomObjectTree((objCmds) => {
          this.store('Store Commands', { ...allCmds, ...objCmds })
        })
      })
    this.httpGet(this.serverUrl + '/services/data/' + this.SFAPI_VERSION + '/sobjects/', (response) => {
      let cmds = parseMeta(response.target.responseText)
      cmds['Refresh Metadata'] = {}
      cmds['Setup'] = {}
      this.store('Store Commands', allCmds)


    })
  }

  parseCustomObjectTree(html) {
    let doc = document.createElement('html')
    doc.innerHtml = html
    let cmds = {}
    document.querySelectorAll('th a').each(function(el) {
        cmds['Setup > Custom Object > ' + this.text] = {url: this.href, key: this.text}
    })

    this.store('Store Commands', cmds)
    return cmds
  }

  getCustomObjects(cb) {
    var theurl = this.serverInstance + '/p/setup/custent/CustomObjectsPage'
    this.httpGet(theurl, 'document', (response) => {
      cb(this.parseSetupTree(response))
    })
  }

  getSetupTree(cb) {
    var theurl = this.serverInstance + '/ui/setup/Setup'
    this.httpGet(theurl, 'document', (response) => {
      cb(this.parseSetupTree(response))
    })
  }

  parseSetupTree () {
    let textLeafSelector = '.setupLeaf > a[id*="_font"]';
    let all = html.querySelectorAll(textLeafSelector)
    let strName
    let as
    let strNameMain
    let cmds = {}
    Array.prototype.map.call(all, function(item) {
      let hasTopParent = false, hasParent = false;
      let parent, topParent;
      let parentEl, topParentEl;

      if (item.parentElement != null && item.parentElement.parentElement != null && item.parentElement.parentElement.parentElement != null
          && item.parentElement.parentElement.parentElement.className.indexOf('parent') !== -1) {

          hasParent = true;
          parentEl = item.parentElement.parentElement.parentElement;
          parent = parentEl.querySelector('.setupFolder').innerText;
      }
      if(hasParent && parentEl.parentElement != null && parentEl.parentElement.parentElement != null
          && parentEl.parentElement.parentElement.className.indexOf('parent') !== -1) {
          hasTopParent = true;
          topParentEl = parentEl.parentElement.parentElement;
          topParent = topParentEl.querySelector('.setupFolder').innerText;
      }

      strNameMain = 'Setup > ' + (hasTopParent ? (topParent + ' > ') : '');
      strNameMain += (hasParent ? (parent + ' > ') : '');

      strName = strNameMain + item.innerText;

      if(cmds[strName] == null) cmds[strName] = {url: item.href, key: strName};

    })
  }

  parseMeta(response) {

    let metadata = JSON.parse(response)

    let isLightning = location.origin.indexOf('lightning') != -1;
    let cmds = {}

    for(let i=0;i<metadata.sobjects.length;i++) {
      if(metadata.sobjects[i].keyPrefix != null) {
        let mRecord = {};
        mRecord.label = metadata.sobjects[i].label;
        mRecord.labelPlural = metadata.sobjects[i].labelPlural;
        mRecord.keyPrefix = metadata.sobjects[i].keyPrefix;
        mRecord.urls = metadata.sobjects[i].urls;

        let act = {};
        act.key = metadata.sobjects[i].name;
        act.keyPrefix = metadata.sobjects[i].keyPrefix;
        act.url = serverInstance + '/' + metadata.sobjects[i].keyPrefix;
        if(isLightning) act.url = location.origin + location.pathname + '#/sObject/' + metadata.sobjects[i].keyPrefix + '/home';

        cmds['List ' + mRecord.labelPlural] = act;
        act = {};
        act.key = metadata.sobjects[i].name;
        act.keyPrefix = metadata.sobjects[i].keyPrefix;
        act.url = serverInstance + '/' + metadata.sobjects[i].keyPrefix;
        act.url += '/e';
        if(isLightning) act.url = location.origin + location.pathname + '#/sObject/' + metadata.sobjects[i].keyPrefix + '/new';

        cmds['New ' + mRecord.label] = act;
      }
    }
    return cmds
  }

  httpGet (url, responseType, callback) {
    var req = new XMLHttpRequest()
    req.open("GET", url, true)
    req.setRequestHeader("Authorization", 'Bearer ' + this.sid)
    req.onload = function(response) {
      callback(response)
    }
    if(responseType) req.responseType = responseType
    req.send()
  }

  getCookie (c_name) {
    var i,x,y,ARRcookies=document.cookie.split(";")
    for (i=0;i<ARRcookies.length;i++) {
      x=ARRcookies[i].substr(0,ARRcookies[i].indexOf("="))
      y=ARRcookies[i].substr(ARRcookies[i].indexOf("=")+1)
      x=x.replace(/^\s+|\s+$/g,"")
      if (x==c_name) return unescape(y)
    }
  }

  getServerUrl () {
    var url = location.origin + "";
    var urlParseArray = url.split(".")

    if(url.indexOf("salesforce") != -1) {
      return url.substring(0, url.indexOf("salesforce")) + "salesforce.com"
    }

    if(url.indexOf("cloudforce") != -1) {
      return url.substring(0, url.indexOf("cloudforce")) + "cloudforce.com"
    }

    if(url.indexOf("visual.force") != -1) {
      return 'https://' + urlParseArray[1] + '.salesforce.com'
    }

    if(url.indexOf("lightning.force.com") != -1) {
      return urlParseArray[0] + '.salesforce.com'
    }
  }

}


class App {

  constructor() {
    this.ui = new ForceNavigatorUI()

  }



}

