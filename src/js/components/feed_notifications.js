function NotificationViewModel(category, message) {
  var self = this;
  self.CATEGORY = category;
  assert(category != "balances" && category != "debits" && category != "credits",
    "Trying to notify on a category that we don't notify on: " + category);
  self.WHEN = new Date().getTime();
  self.ICON_CLASS = NotificationViewModel.calcIconClass(category);
  self.COLOR_CLASS = NotificationViewModel.calcColorClass(category);
  self.MESSAGE = message;
  self.MESSAGE_TEXT = NotificationViewModel.calcText(category, message);

}

NotificationViewModel.calcIconClass = function(category) {
  /*
   * Possible categories:
   * user: Misc user notification (not critical)
   * alert: Something to alert the user to at a notification level
   * security: Security-related notification
   * 
   * Beyond this, any one of the valid message category types:
   * credits, debits, broadcasts, etc
   */
  if (category == 'user') return 'fa-user';
  if (category == 'alert') return 'fa-exclamation';
  if (category == 'security') return 'fa-shield';
  return ENTITY_ICONS[category] ? ENTITY_ICONS[category] : 'fa-question';
}
NotificationViewModel.calcColorClass = function(category) {
  if (category == 'user') return 'bg-color-lighten';
  if (category == 'alert') return 'bg-color-redLight';
  if (category == 'security') return 'bg-color-redLight';
  return ENTITY_NOTO_COLORS[category] ? ENTITY_NOTO_COLORS[category] : 'bg-color-white';
}
NotificationViewModel.calcText = function(category, message) {
  //Run through this function only once for each notification -- when the notification is initially received (and
  // before the underlying wallet/asset/whatever state has been modified, so that we can compare new to existing states
  // -- if we need to -- to be able to see what changed, which is important in the case of asset issuances, for instance)
  var desc = "";

  if (category == "sends") {
    if (WALLET.getAddressObj(message['source']) && WALLET.getAddressObj(message['destination'])) {
      desc = i18n.t("notif_you_transferred", smartFormat(normalizeQuantity(message['quantity'], message['_asset_divisible'])),
        message['_asset_longname'] || message['asset'], getAddressLabel(message['source']), getAddressLabel(message['destination']));
    } else if (WALLET.getAddressObj(message['source'])) { //we sent funds
      desc = i18n.t("notif_you_sent", smartFormat(normalizeQuantity(message['quantity'], message['_asset_divisible'])),
        message['_asset_longname'] || message['asset'], getAddressLabel(message['source']), getAddressLabel(message['destination']));
    } else if (WALLET.getAddressObj(message['destination'])) { //we received funds
      desc = i18n.t("notif_you_received", smartFormat(normalizeQuantity(message['quantity'], message['_asset_divisible'])),
        message['_asset_longname'] || message['asset'], getAddressLabel(message['source']), getAddressLabel(message['destination']));
    }
  } else if (category == "proofofwork" && WALLET.getAddressObj(message['source'])) {
    desc = i18n.t("notif_proofofwork", getAddressLabel(message['source']), smartFormat(normalizeQuantity(message['mined'])),
      smartFormat(normalizeQuantity(message['earned'])));
  } else if (category == "dividend") {
    //See if any of our addresses own any of the specified asset, and if so, notify them of the callback or dividend
    // NOTE that aspire has automatically already adusted the balances of all asset holders...we just need to notify
    var addressesWithAsset = WALLET.getAddressesWithAsset(message['asset']);
    if (!addressesWithAsset.length) return;
    desc = i18n.t("notif_dividend_done", message['_dividend_asset_longname'] || message['dividend_asset'],
      addressesWithAsset.join(', '), message['quantity_per_unit'], message['_asset_longname'] || message['asset']);
  } else if (category == 'issuances') {
    var addresses = WALLET.getAddressesList();
    var assetObj = null;
    var addressesWithAsset = WALLET.getAddressesWithAsset(message['asset']);
    if (addressesWithAsset.length)
      assetObj = WALLET.getAddressObj(addressesWithAsset[0]).getAssetObj(message['asset']);

    if (message['transfer']) {
      //Detect transfers, whether we currently have the object in our wallet or not (as it could be
      // a transfer FROM an address outside of our wallet)
      if (addresses.indexOf(message['source']) != -1 || addresses.indexOf(message['issuer']) != -1) {
        desc = i18n.t("notif_token_transferred", message['_asset_longname'] || message['asset'], getLinkForCPData('address', message['source'], getAddressLabel(message['source'])),
          getLinkForCPData('address', message['issuer'], getAddressLabel(message['issuer'])));
      }
    } else if (assetObj) { //the address is in the wallet
      //Detect everything else besides transfers, which we only care to see if the asset is listed in one of the wallet addresses
      if (message['locked']) {
        assert(!assetObj.locked());
        desc = i18n.t("notif_token_locked", message['_asset_longname'] || message['asset']);
      } else if (message['description'] != assetObj.description()) {
        desc = i18n.t("notif_token_desc_changed", message['_asset_longname'] || message['asset'], assetObj.description(), message['description']);
      } else {
        var additionalQuantity = message['quantity'];
        if (additionalQuantity) {
          desc = i18n.t("notif_additional_issued", smartFormat(normalizeQuantity(additionalQuantity, assetObj.DIVISIBLE)), message['_asset_longname'] || message['asset']);
        } else {
          //this is not a transfer, but it is not in our wallet as well we can assume it's an issuance of a totally new asset
          desc = i18n.t("notif_token_issued", message['_asset_longname'] || message['asset'], smartFormat(normalizeQuantity(message['quantity'], message['divisible'])));
        }
      }
    }
  } else if (category == "broadcasts" && WALLET.getAddressObj(message['source'])) {
    if (message['locked']) {
      desc = i18n.t("notif_feed_locked", getAddressLabel(message['source']));
    } else {
      desc = i18n.t("notif_value_broadcasted", message['value'], getAddressLabel(message['source']));
    }
  } else {
    console.log('feed_notifications.js:146 - unknown category "', category, '"');
  }

  if (desc) {
    desc = desc.replace(/<Am>/g, '<b class="notoQuantityColor">').replace(/<\/Am>/g, '</b>');
    desc = desc.replace(/<Ad>/g, '<b class="notoAddrColor">').replace(/<\/Ad>/g, '</b>');
    desc = desc.replace(/<As>/g, '<b class="notoAssetColor">').replace(/<\/As>/g, '</b>');
  }
  return desc;
}


function NotificationFeedViewModel(initialCount) {
  var self = this;

  self.entries = ko.observableArray([]);
  self.lastUpdated = ko.observable(new Date());
  self.count = ko.observable(initialCount || 0);
  self.unackedCount = ko.observable(initialCount || 0);

  self.ack = function() {
    self.unackedCount(0);
  }

  self.add = function(category, message) {
    if (category == "balances" || category == "debits" || category == "credits") return;
    //^ we don't notify on these categories (since the action is covered by other categories, such as send, which makes these redundant)

    var noto = new NotificationViewModel(category, message);
    if (!noto.MESSAGE_TEXT)
      return; //will be the case if this noto does not apply to this client or is not something this client needs to see

    self.entries.unshift(noto); //add to front of array
    self.unackedCount(self.unackedCount() + 1);
    //if the number of entries are over 40, remove the oldest one
    if (self.entries().length > 40) self.entries.pop();
    self.lastUpdated(new Date());
    WALLET.refreshGASPBalances();

    //Also notify the user via a CSS popup, so the action completing is more appearent.
    //noty({type: 'success', text: noto.MESSAGE_TEXT, timeout: 10000});
    $.smallBox({content: noto.MESSAGE_TEXT, timeout: 10000, color: "#fbfbfb", iconSmall : "fa fa-check"});
  }
}

/*NOTE: Any code here is only triggered the first time the page is visited. Put JS that needs to run on the
  first load and subsequent ajax page switches in the .html <script> tag*/
