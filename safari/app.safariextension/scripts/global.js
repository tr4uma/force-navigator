'use strict';

var BackgroundPage = function() {

  var commands = {};
  var metadata = {};





  // this. function bigCalc(startVal, event) {
  //     // imagine hundreds of lines of code here...
  //     var endVal = startVal + 2;
  //     // return to sender
  //     event.target.page.dispatchMessage("theAnswer", endVal);
  // }




  this.messageHandler = function(request, sender, sendResponse) {

    var reply = function(respondFn, eventMsg, data) {
      if(respondFn != null) respondFn(data);
      else if(eventMsg.target != null) eventMsg.target.page.dispatchMessage(eventMsg.name, data);
    }

      var msgName = request.name;
      var data = request.message;
      var key = data == null ? null : data.key;
      console.log(key);
      // if(chrome != null) msgName = request.name;
      // else if(safari != null) msgName = request.name;


      if(msgName == 'Store Commands')
      {
        commands[key] = commands[key.split('!')[0]] = request.payload;
        reply(sendResponse, request, {});
      }
      if(msgName == 'Get Commands')
      {
        if(commands[key] != null)
          reply(sendResponse, request, commands[key]);
        else if(commands[key.split('!')[0]] != null)
          reply(sendResponse, request, commands[key.split('!')[0]]);
        else
          reply(sendResponse, request, null);
      }
      if(msgName == 'Get Settings')
      {
        var settings = localStorage.getItem('sfnav_settings');
        console.log('settings: ' + settings);
        if(settings != null)
        {
          reply(sendResponse, request, JSON.parse(settings));
        }
        else
        {
          var sett = {};
          sett['shortcut'] = 'ctrl+shift+space';
          localStorage.setItem('sfnav_settings', JSON.stringify(sett));
          reply(sendResponse, request, sett);
        }
      }
      if(msgName == 'Set Settings')
      {
        var settings = localStorage.getItem('sfnav_settings');
        if(settings != null)
        {
          var sett = JSON.parse(settings);
          sett['shortcut'] = request.payload;
          localStorage.setItem('sfnav_settings', JSON.stringify(sett));
        }
        reply(sendResponse, request, {});
      }
      if(msgName == 'Store Metadata')
      {
        metadata[key] = metadata[key.split('!')[0]] = request.payload;
        reply(sendResponse, request, {});
      }
      if(msgName == 'Get Metadata')
      {
        if(metadata[key] != null)
          reply(sendResponse, request, metadata[key]);
        else if(metadata[key.split('!')[0]] != null)
          reply(sendResponse, request, metadata[key.split('!')[0]]);
        else
          reply(sendResponse, request, null);
      }
  }


};

var bgPage = new BackgroundPage();

safari.application.addEventListener("message",bgPage.messageHandler,false);

