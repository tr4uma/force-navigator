
var Messaging = function() {

    function Messaging() {}

    this.sendMessage = function(name, data, responseFn) {
        if(window.chrome != null) chrome.extension.sendMessage(name, {"data":data}, responseFn);
        else if (window.safari != null) window.safari.self.tab.dispatchMessage(name,data);
    }

    this.listenFor = function(name, responseFn) {
        if(listeners[name] != null) {
            // if(window.chrome != null) chrome.extension.removeListener(listeners[name]);
            // else if(window.safari != null) window.safari.self.removeEventListener(listeners[name]);
        }
        listeners[name] = responseFn;

        // if(window.chrome != null) chrome.extension.onMessage.addListener(listeners[name]);
        // else if(window.safari != null) window.safari.self.tab.addEventListener("message",listeners[name]);
    }

    this.addListeners = function() {

        if(window.chrome != null) chrome.extension.onMessage.addListener(messageListener);
        else if(window.safari != null) window.safari.self.addEventListener("message",messageListener);
    }

    this.messageListener = function(msg) {
        if(listeners[msg.name] != null) listeners[msg.name].apply(this, [msg.message]);
    }
}

module.exports = Messaging;


