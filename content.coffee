# @copyright 2012+ Daniel Nakov / Silverline CRM
# http://silverlinecrm.com
Messaging = require("./messaging.js")
MSG = new Messaging()
Mousetrap = require("mousetrap")
$ = require("jquery")

Mousetrap = ((Mousetrap) ->
    _global_callbacks = {}
    _original_stop_callback = Mousetrap.stopCallback
    Mousetrap.stopCallback = (e, element, combo) ->
      return false  if _global_callbacks[combo]
      _original_stop_callback e, element, combo

    Mousetrap.bindGlobal = (keys, callback, action) ->
      Mousetrap.bind keys, callback, action
      if keys instanceof Array
        i = 0

        while i < keys.length
          _global_callbacks[keys[i]] = true
          i++
        return
      _global_callbacks[keys] = true
      return

    Mousetrap
  )(Mousetrap)



class ContentScript
    @outp = null
    @oldins = null
    @posi = -1
    @newTabKeys = [
      "ctrl+enter"
      "command+enter"
      "shift+enter"
    ]
    @input = null
    @isVisible = false
    @key = null
    @metaData = {}
    @serverInstance = getServerInstance()
    @cmds = {}
    @isCtrl = false
    @clientId = ""
    @omnomnom = ""
    @hash = ""
    @loaded = false
    @shortcut = null
    @sid = null
    @SFAPI_VERSION = "v28.0"
    @ftClient = null
    @listeners = {}
    @customObjects = {}
    @META_DATATYPES =
      AUTONUMBER:
        name: "AutoNumber"
        code: "auto"
        params: 0

      CHECKBOX:
        name: "Checkbox"
        code: "cb"
        params: 0

      CURRENCY:
        name: "Currency"
        code: "curr"
        params: 2

      DATE:
        name: "Date"
        code: "d"
        params: 0

      DATETIME:
        name: "DateTime"
        code: "dt"
        params: 0

      EMAIL:
        name: "Email"
        code: "e"
        params: 0

      FORMULA:
        name: "FORMULA"
        code: "form"

      GEOLOCATION:
        name: "Location"
        code: "geo"

      HIERARCHICALRELATIONSHIP:
        name: "Hierarchy"
        code: "hr"

      LOOKUP:
        name: "Lookup"
        code: "look"

      MASTERDETAIL:
        name: "MasterDetail"
        code: "md"

      NUMBER:
        name: "Number"
        code: "n"

      PERCENT:
        name: "Percent"
        code: "per"

      PHONE:
        name: "Phone"
        code: "ph"

      PICKLIST:
        name: "Picklist"
        code: "pl"

      PICKLISTMS:
        name: "MultiselectPicklist"
        code: "plms"

      ROLLUPSUMMARY:
        name: "Summary"
        code: "rup"

      TEXT:
        name: "Text"
        code: "t"

      TEXTENCRYPTED:
        name: "EcryptedText"
        code: "te"

      TEXTAREA:
        name: "TextArea"
        code: "ta"

      TEXTAREALONG:
        name: "LongTextArea"
        code: "tal"

      TEXTAREARICH:
        name: "Html"
        code: "tar"

      URL:
        name: "Url"
        code: "url"

    return

  ###*
  adds a bindGlobal method to Mousetrap that allows you to
  bind specific keyboard shortcuts that will still work
  inside a text input field

  usage:
  Mousetrap.bindGlobal('ctrl+s', _saveChanges);
  ###
  getSingleObjectMetadata: ->
    recordId = document.URL.split("/")[3]
    keyPrefix = recordId.substring(0, 3)
    return
  addElements: (ins) ->
    if ins.substring(0, 3) is "cf " and ins.split(" ").length < 4
      @clearOutput()
      @addWord "Usage: cf <Object API Name> <Field Name> <Data Type>"
      @setVisible "visible"
    else if ins.substring(0, 3) is "cf " and ins.split(" ").length is 4
      @clearOutput()
      @wordArray = ins.split(" ")
      @words = getWord(wordArray[3], META_DATATYPES)
      words2 = []
      i = 0

      while i < @words.length
        switch @words[i].toUpperCase()
          when "AUTONUMBER"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i]
          when "CHECKBOX"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i]
          when "CURRENCY"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i] + " <scale> <precision>"
          when "DATE"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i]
          when "DATETIME"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i]
          when "EMAIL"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i]
          when "FORMULA", "GEOLOCATION"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i] + " <scale>"
          when "HIERARCHICALRELATIONSHIP", "LOOKUP"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i] + " <lookup sObjectName>"
          when "MASTERDETAIL", "NUMBER"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i] + " <scale> <precision>"
          when "PERCENT"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i] + " <scale> <precision>"
          when "PHONE"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i]
          when "PICKLIST"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i]
          when "PICKLISTMS"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i]
          when "ROLLUPSUMMARY", "TEXT"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i] + " <length>"
          when "TEXTENCRYPTED", "TEXTAREA"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i] + " <length>"
          when "TEXTAREALONG"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i] + " <length> <visible lines>"
          when "TEXTAREARICH"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i] + " <length> <visible lines>"
          when "URL"
            words2.push wordArray[0] + " " + wordArray[1] + " " + wordArray[2] + " " + words[i]
        i++
      if words2.length > 0
        clearOutput()
        i = 0

        while i < words2.length
          @addWord words2[i]
          ++i
        @setVisible "visible"
        @input = document.getElementById("sfnav_quickSearch").value
      else
        @setVisible "hidden"
        @posi = -1

      #
      #            for(var i=0;i<Object.keys(META_DATATYPES).length;i++)
      #            {
      #                addWord(Object.keys(META_DATATYPES)[i]);
      #            }
      #
      @setVisible "visible"
    else if ins.substring(0, 3) is "cf " and ins.split(" ").length > 4
      @clearOutput()
    else
      @words = @getWord(ins, cmds)
      if @words.length > 0
        @clearOutput()
        i = 0

        while i < @words.length
          addWord @words[i]
          ++i
        @setVisible "visible"
        @input = document.getElementById("sfnav_quickSearch").value
      else
        @setVisible "hidden"
        @posi = -1
    return
  httpGet: (url, callback) ->
    req = new XMLHttpRequest()
    req.open "GET", url, true
    req.setRequestHeader "Authorization", sid
    req.onload = (response) ->
      callback response
      return

    req.send()
    return
  setVisible: (visi) ->
    x = document.getElementById("sfnav_shadow")
    t = document.getElementById("sfnav_quickSearch")
    x.style.position = "relative"
    x.style.visibility = visi
    return
  setVisibleSearch: (visi) ->
    if visi is "hidden"
      isVisible = false
    else
      isVisible = true
    t = document.getElementById("sfnav_search_box")
    t.style.visibility = visi
    document.getElementById("sfnav_quickSearch").focus()  if visi is "visible"
    return
  lookAt: ->
    @ins = document.getElementById("sfnav_quickSearch").value
    if @oldins is @ins and @ins.length > 0
      return
    else if @posi > -1

    else if @ins.length > 0
      @addElements ins
    else
      @setVisible "hidden"
      @posi = -1
    @oldins = @ins
    return
  addWord: (word) ->
    d = document.createElement("div")
    sp = undefined
    if @cmds[word].url? and @cmds[word].url isnt ""
      sp = document.createElement("a")
      sp.setAttribute "href", cmds[word].url
    else
      sp = d
    sp.className = "sfnav_child"
    sp.appendChild document.createTextNode(word)
    sp.onmouseover = mouseHandler
    sp.onmouseout = mouseHandlerOut
    sp.onclick = mouseClick
    @outp.appendChild sp
    return
  addSuccess: (text) ->
    @clearOutput()
    err = document.createElement("div")
    err.className = "sfnav_child sfnav-success-wrapper"
    errorText = ""
    err.appendChild document.createTextNode("Success! ")
    err.appendChild document.createElement("br")
    err.appendChild document.createTextNode("Field " + text.id + " created!")
    @outp.appendChild err
    @setVisible "visible"
    return
  addError: (text) ->
    @clearOutput()
    err = document.createElement("div")
    err.className = "sfnav_child sfnav-error-wrapper"
    errorText = ""
    err.appendChild document.createTextNode("Error! ")
    err.appendChild document.createElement("br")
    i = 0

    while i < text.length
      err.appendChild document.createTextNode(text[i].message)
      err.appendChild document.createElement("br")
      i++

    #
    #        var ta = document.createElement('textarea');
    #        ta.className = 'sfnav-error-textarea';
    #        ta.value = JSON.stringify(text, null, 4);
    #
    #        err.appendChild(ta);
    #
    @outp.appendChild err
    @setVisible "visible"
    return
  clearOutput: ->
    unless typeof @outp is "undefined"
      while @outp.hasChildNodes()
        noten = outp.firstChild
        outp.removeChild noten
    @posi = -1
    return
  getWord: (beginning, dict) ->
    @words = []
    return []  if typeof beginning is "undefined"
    tmpSplit = beginning.split(" ")
    match = false
    if beginning.length is 0
      for key of dict
        words.push key
      return words
    arrFound = []
    for key of dict
      match = false
      unless key.toLowerCase().indexOf(beginning) is -1
        arrFound.push
          num: 10
          key: key

      else
        i = 0

        while i < tmpSplit.length
          unless key.toLowerCase().indexOf(tmpSplit[i].toLowerCase()) is -1
            match = true
          else
            match = false
            break
          i++
        if match
          arrFound.push
            num: 1
            key: key

    arrFound.sort (a, b) ->
      b.num - a.num

    i = 0

    while i < arrFound.length
      @words[@words.length] = arrFound[i].key
      i++
    words
  setColor: (_posi, _color, _forg) ->
    @outp.childNodes[_posi].style.background = _color
    @outp.childNodes[_posi].style.color = _forg
    return
  invokeCommand: (cmd, newtab, event) ->
    if event isnt "click" and typeof @cmds[cmd] isnt "undefined" and (@cmds[cmd].url? or @cmds[cmd].url is "")
      if newtab
        w = window.open(@cmds[cmd].url, "_newtab")
        w.blur()
        window.focus()
      else
        window.location.href = @cmds[cmd].url
      return true
    if cmd.toLowerCase() is "refresh metadata"
      @showLoadingIndicator()
      @getAllObjectMetadata()
      setTimeout (=>
        @hideLoadingIndicator()
        return
      ), 30000
      return true
    if cmd.toLowerCase() is "setup"
      window.location.href = @serverInstance + ".salesforce.com/ui/setup/Setup"
      return true
    if cmd.toLowerCase().substring(0, 3) is "cf "
      @createField cmd
      return true
    false
  updateField:  (cmd) ->
    arrSplit = cmd.split(" ")
    dataType = ""
    fieldMetadata = undefined
    if arrSplit.length >= 3
      for key of META_DATATYPES
        if META_DATATYPES[key].name.toLowerCase() is arrSplit[3].toLowerCase()
          dataType = META_DATATYPES[key].name
          break
      sObjectName = arrSplit[1]
      fieldName = arrSplit[2]
      helpText = null
      typeLength = arrSplit[4]
      rightDecimals = undefined
      leftDecimals = undefined
      unless parseInt(arrSplit[5]) is NaN
        rightDecimals = parseInt(arrSplit[5])
        leftDecimals = typeLength
      else
        leftDecimals = 0
        rightDecimals = 0
      @ftClient.queryByName "CustomField", fieldName, sObjectName, ((success) ->
        @addSuccess success
        fieldMeta = new forceTooling.CustomFields.CustomField(arrSplit[1], arrSplit[2], dataType, null, arrSplit[4], parseInt(leftDecimals), parseInt(rightDecimals), null)
        @ftClient.update "CustomField", fieldMeta, ((success) ->
          console.log success
          addSuccess success
          return
        ), (error) ->
          console.log error
          addError error.responseJSON
          return

        return
      ), (error) ->
        addError error.responseJSON
        return

    return
  createField: (cmd) ->
    arrSplit = cmd.split(" ")
    dataType = ""
    fieldMetadata = undefined
    if arrSplit.length >= 3

      #  forceTooling.Client.create(whatever)
      #
      #            for(var key in META_DATATYPES)
      #            {
      #                if(META_DATATYPES[key].name.toLowerCase() === arrSplit[3].toLowerCase())
      #                {
      #                    dataType = META_DATATYPES[key].name;
      #                    break;
      #                }
      #            }
      #
      dataType = META_DATATYPES[arrSplit[3].toUpperCase()].name
      sObjectName = arrSplit[1]
      sObjectId = null
      if typeof customObjects[sObjectName.toLowerCase()] isnt "undefined"
        sObjectId = customObjects[sObjectName.toLowerCase()].Id
        sObjectName += "__c"
      fieldName = arrSplit[2]
      helpText = null
      typeLength = arrSplit[4]
      rightDecimals = undefined
      leftDecimals = undefined
      unless parseInt(arrSplit[5]) is NaN
        rightDecimals = parseInt(arrSplit[5])
        leftDecimals = parseInt(typeLength)
      else
        leftDecimals = 0
        rightDecimals = 0
      fieldMeta = undefined
      switch arrSplit[3].toUpperCase()
        when "AUTONUMBER"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, null, null, null, null, null, 0)
        when "CHECKBOX"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, null, null, null, null, null, 0)
        when "CURRENCY"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, null, leftDecimals, rightDecimals, null, null, 0)
        when "DATE"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, null, null, null, null, null, 0)
        when "DATETIME"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, null, null, null, null, null, 0)
        when "EMAIL"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, null, null, null, null, null, 0)
        when "FORMULA", "GEOLOCATION"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, null, null, arrSplit[4], null, null, 0)
        when "HIERARCHICALRELATIONSHIP"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, null, null, null, null, arrSplit[4], 0)
        when "LOOKUP"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, null, null, null, null, arrSplit[4], 0)
        when "MASTERDETAIL"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, null, null, null, null, arrSplit[4], 0)
        when "NUMBER"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, null, leftDecimals, rightDecimals, null, null, 0)
        when "PERCENT"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, null, leftDecimals, rightDecimals, null, null, 0)
        when "PHONE"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, null, null, null, null, null, 0)
        when "PICKLIST"
          plVal = []
          plVal.push new forceTooling.CustomFields.PicklistValue("CHANGEME")
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, null, null, null, plVal, null, 0)
        when "PICKLISTMS"
          plVal = []
          plVal.push new forceTooling.CustomFields.PicklistValue("CHANGEME")
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, null, null, null, plVal, null, 0)
        when "ROLLUPSUMMARY", "TEXT"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, typeLength, null, null, null, null, 0)
        when "TEXTENCRYPTED"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, null, null, null, null, null, 0)
        when "TEXTAREA"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, typeLength, null, null, null, null, 0)
        when "TEXTAREALONG"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, typeLength, null, null, null, null, arrSplit[4])
        when "TEXTAREARICH"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, typeLength, null, null, null, null, arrSplit[4])
        when "URL"
          fieldMeta = new forceTooling.CustomFields.CustomField(sObjectName, sObjectId, fieldName, dataType, null, null, null, null, null, null, 0)
      @ftClient.setSessionToken getCookie("sid"), SFAPI_VERSION, serverInstance + ".salesforce.com"
      @showLoadingIndicator()
      @ftClient.create "CustomField", fieldMeta, ((success) ->
        console.log success
        @hideLoadingIndicator()
        @addSuccess success
        return
      ), (error) ->
        console.log error
        @hideLoadingIndicator()
        @addError error.responseJSON
        return

    return

  getMetadata: (_data) ->
    return  if _data.length is 0
    @metadata = JSON.parse(_data)
    mRecord = {}
    act = {}
    metaData = {}
    i = 0

    while i < @metadata.sobjects.length
      if @metadata.sobjects[i].keyPrefix?
        mRecord = {}
        mRecord.label = @metadata.sobjects[i].label
        mRecord.labelPlural = @metadata.sobjects[i].labelPlural
        mRecord.keyPrefix = @metadata.sobjects[i].keyPrefix
        mRecord.urls = @metadata.sobjects[i].urls
        @metaData[@metadata.sobjects[i].keyPrefix] = mRecord
        act = {}
        act.key = @metadata.sobjects[i].name
        act.keyPrefix = @metadata.sobjects[i].keyPrefix
        act.url = serverInstance + ".salesforce.com/" + @metadata.sobjects[i].keyPrefix
        cmds["List " + mRecord.labelPlural] = act
        act = {}
        act.key = @metadata.sobjects[i].name
        act.keyPrefix = @metadata.sobjects[i].keyPrefix
        act.url = serverInstance + ".salesforce.com/" + @metadata.sobjects[i].keyPrefix
        act.url += "/e"
        cmds["New " + mRecord.label] = act
      i++
    store "Store Commands", cmds
    store "Store Metadata", metaData
    return
  store: (action, payload) ->
    req = {}
    req.name = action
    req.data =
      key: hash
      payload: payload

    MSG.sendMessage req.name, req.data
    return

  # var storagePayload = {};
  # storagePayload[action] = payload;
  # chrome.storage.local.set(storagePayload, function() {
  #     console.log('stored');
  # });
  getAllObjectMetadata: ->

    # session ID is different and useless in VF
    return  if location.origin.indexOf("visual.force") isnt -1
    @sid = "Bearer " + getCookie("sid")
    @theurl = getServerInstance() + ".salesforce.com/services/data/" + SFAPI_VERSION + "/sobjects/"
    @cmds["Refresh Metadata"] = {}
    @cmds["Setup"] = {}
    req = new XMLHttpRequest()
    req.open "GET", theurl, true
    req.setRequestHeader "Authorization", sid
    req.onload = (response) =>
      @getMetadata response.target.responseText
      return

    req.send()
    @getSetupTree()

    # getCustomObjects();
    @getCustomObjectsDef()
    return
  parseSetupTree: (html) ->
    allLinks = html.getElementById("setupNavTree").getElementsByClassName("parent")
    strName = undefined
    as = undefined
    strNameMain = undefined
    strName = undefined
    i = 0

    while i < allLinks.length
      as = allLinks[i].getElementsByTagName("a")
      j = 0

      while j < as.length
        unless as[j].id.indexOf("_font") is -1
          strNameMain = "Setup > " + as[j].text + " > "
          break
        j++
      children = allLinks[i].querySelectorAll(".childContainer > .setupLeaf > a")
      j = 0

      while j < children.length
        if children[j].text.length > 2
          strName = strNameMain + children[j].text
          unless cmds[strName]?
            @cmds[strName] =
              url: children[j].href
              key: strName
        j++
      i++
    @store "Store Commands", cmds
    return
  getSetupTree: ->
    @theurl = serverInstance + ".salesforce.com/ui/setup/Setup"
    req = new XMLHttpRequest()
    req.onload = (response) =>
      @parseSetupTree response
      @hideLoadingIndicator()
      return

    req.open "GET", theurl
    req.responseType = "document"
    req.send()
    return
  getCustomObjects: ->
    @theurl = serverInstance + ".salesforce.com/p/setup/custent/CustomObjectsPage"
    req = new XMLHttpRequest()
    req.onload = ->
      parseCustomObjectTree @response
      return

    req.open "GET", theurl
    req.responseType = "document"
    req.send()
    return
  parseCustomObjectTree = (html) ->
    $(html).find("th a").each (el) ->
      cmds["Setup > Custom Object > " + @text] =
        url: @href
        key: @text

      return

    store "Store Commands", cmds
    return
  getCookie: (c_name) ->
    i = undefined
    x = undefined
    y = undefined
    ARRcookies = document.cookie.split(";")
    i = 0
    while i < ARRcookies.length
      x = ARRcookies[i].substr(0, ARRcookies[i].indexOf("="))
      y = ARRcookies[i].substr(ARRcookies[i].indexOf("=") + 1)
      x = x.replace(/^\s+|\s+$/g, "")
      return unescape(y)  if x is c_name
      i++
    return
  getServerInstance: ->
    url = location.origin + ""
    urlParseArray = url.split(".")
    i = undefined
    returnUrl = undefined
    unless url.indexOf("salesforce") is -1
      returnUrl = url.substring(0, url.indexOf("salesforce") - 1)
      return returnUrl
    unless url.indexOf("visual.force") is -1
      returnUrl = "https://" + urlParseArray[1]
      return returnUrl
    returnUrl
  initShortcuts: ->
    MSG.sendMessage "Get Settings"
    MSG.listenFor "Get Settings", (response) ->
      shortcut = response["shortcut"]
      bindShortcut shortcut
      return

    return

  # chrome.storage.local.get('settings', function(results) {
  #     if(typeof results.settings.shortcut === 'undefined')
  #     {
  #         shortcut = 'shift+space';
  #         bindShortcut(shortcut);
  #     }
  #     else
  #     {
  #         bindShortcut(results.settings.shortcut);
  #     }
  # });
  kbdCommand: (e, key) ->
    position = posi
    origText = ""
    newText = ""
    position = 0  if position < 0
    origText = document.getElementById("sfnav_quickSearch").value
    newText = outp.childNodes[position].firstChild.nodeValue  unless typeof outp.childNodes[position] is "undefined"
    newtab = (if newTabKeys.indexOf(key) >= 0 then true else false)
    setVisible "hidden"  unless newtab
    invokeCommand origText, newtab  unless invokeCommand(newText, newtab)
    return
  bindShortcut: (shortcut) ->
    Mousetrap.bindGlobal shortcut, (e) ->
      setVisibleSearch "visible"
      false

    Mousetrap.wrap(document.getElementById("sfnav_quickSearch")).bind "esc", (e) ->
      document.getElementById("sfnav_quickSearch").blur()
      clearOutput()
      document.getElementById("sfnav_quickSearch").value = ""
      setVisible "hidden"
      setVisibleSearch "hidden"
      return

    Mousetrap.wrap(document.getElementById("sfnav_quickSearch")).bind "enter", kbdCommand
    i = 0

    while i < newTabKeys.length
      Mousetrap.wrap(document.getElementById("sfnav_quickSearch")).bind newTabKeys[i], kbdCommand
      i++
    Mousetrap.wrap(document.getElementById("sfnav_quickSearch")).bind "down", (e) ->
      firstChild = undefined
      lookAt()
      if outp.childNodes[posi]?
        firstChild = outp.childNodes[posi].firstChild.nodeValue
      else
        firstChild = null
      textfield = document.getElementById("sfnav_quickSearch")
      if words.length > 0 and posi < words.length - 1
        posi++
        if outp.childNodes[posi]?
          firstChild = outp.childNodes[posi].firstChild.nodeValue
        else
          firstChild = null
        if posi >= 1
          outp.childNodes[posi - 1].classList.remove "sfnav_selected"
        else
          input = textfield.value
        outp.childNodes[posi].classList.add "sfnav_selected"
        textfield.value = firstChild
        if textfield.value.indexOf("<") isnt -1 and textfield.value.indexOf(">") isnt -1
          textfield.setSelectionRange textfield.value.indexOf("<"), textfield.value.length
          textfield.focus()
          false

    Mousetrap.wrap(document.getElementById("sfnav_quickSearch")).bind "up", (e) ->
      firstChild = undefined
      if outp.childNodes[posi]?
        firstChild = outp.childNodes[posi].firstChild.nodeValue
      else
        firstChild = null
      textfield = document.getElementById("sfnav_quickSearch")
      if words.length > 0 and posi >= 0
        posi--
        if outp.childNodes[posi]?
          firstChild = outp.childNodes[posi].firstChild.nodeValue
        else
          firstChild = null
        if posi >= 0
          outp.childNodes[posi + 1].classList.remove "sfnav_selected"
          outp.childNodes[posi].classList.add "sfnav_selected"
          textfield.value = firstChild
        else
          outp.childNodes[posi + 1].classList.remove "sfnav_selected"
          textfield.value = input
        if textfield.value.indexOf("<") isnt -1 and textfield.value.indexOf(">") isnt -1
          textfield.setSelectionRange textfield.value.indexOf("<"), textfield.value.length
          textfield.focus()
          false

    Mousetrap.wrap(document.getElementById("sfnav_quickSearch")).bind "backspace", (e) ->
      posi = -1
      oldins = -1
      return

    document.getElementById("sfnav_quickSearch").onkeyup = ->
      lookAt()
      true

    return
  showLoadingIndicator: ->
    document.getElementById("sfnav_loader").style.visibility = "visible"
    return
  hideLoadingIndicator: ->
    document.getElementById("sfnav_loader").style.visibility = "hidden"
    return
  getCustomObjectsDef: ->
    @ftClient.query "Select+Id,+DeveloperName,+NamespacePrefix+FROM+CustomObject", ((success) ->
      i = 0

      while i < success.records.length
        customObjects[success.records[i].DeveloperName.toLowerCase()] = Id: success.records[i].Id
        apiName = ((if not success.records[i].NamespacePrefix? then "" else success.records[i].NamespacePrefix + "__")) + success.records[i].DeveloperName + "__c"
        cmds["Setup > Custom Object > " + apiName] =
          url: "/" + success.records[i].Id
          key: apiName
        i++
      return
    ), (error) ->
      getCustomObjects()
      return

    return
  init: ->
    @ftClient = new forceTooling.Client()
    @ftClient.setSessionToken getCookie("sid"), SFAPI_VERSION, serverInstance + ".salesforce.com"
    div = document.createElement("div")
    div.setAttribute "id", "sfnav_search_box"
    loaderURL = "" #chrome.extension.getURL("images/ajax-loader.gif");
    div.innerHTML = "<div class=\"sfnav_wrapper\"><input type=\"text\" id=\"sfnav_quickSearch\" autocomplete=\"off\"/><img id=\"sfnav_loader\" src= \"" + loaderURL + "\"/></div><div class=\"sfnav_shadow\" id=\"sfnav_shadow\"/><div class=\"sfnav_output\" id=\"sfnav_output\"/>"
    document.body.appendChild div
    outp = document.getElementById("sfnav_output")
    hideLoadingIndicator()
    initShortcuts()
    omnomnom = getCookie("sid")
    clientId = omnomnom.split("!")[0]
    hash = clientId + "!" + omnomnom.substring(omnomnom.length - 10, omnomnom.length)

    # chrome.storage.local.get(['Commands','Metadata'], function(results) {
    #     console.log(results);
    # });
    MSG.sendMessage "Get Commands",
      key: hash

    MSG.listenFor "Get Commands", (response) ->
      cmds = response
      if not cmds? or cmds.length is 0
        cmds = {}
        metaData = {}
        getAllObjectMetadata()
      else

      return

    MSG.sendMessage "Get Metadata",
      key: hash

    MSG.listenFor "Get Metadata", (response) ->
      metaData = response
      return

    return

  mouseHandler: ->
    @classList.add "sfnav_selected"
    true

  mouseHandlerOut: ->
    @classList.remove "sfnav_selected"
    true

  mouseClick: ->
    document.getElementById("sfnav_quickSearch").value = @firstChild.nodeValue
    @setVisible "hidden"
    @posi = -1
    @oldins = @firstChild.nodeValue
    @setVisibleSearch "hidden"
    @setVisible "hidden"
    @invokeCommand @firstChild.nodeValue, false, "click"
    true

  @addListeners()

  if not @serverInstance? or not @getCookie("sid")? or @getCookie("sid").split("!").length isnt 2
    return
  else
    @init()
  return

module.exports = ContentScript()
