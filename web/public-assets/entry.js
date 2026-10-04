/* Public content stays readable. Only existing app links and installed PWAs enter the app. */
(function () {
  'use strict';
  var current = new URL(window.location.href);
  var appKeys = ['creator', 'code', 'referrer', 'refcode', 'mode', 'oobCode'];
  var isCheckoutReturn = ['success', 'cancelled'].indexOf(current.searchParams.get('checkout')) !== -1;
  var isAppLink = current.hash.indexOf('#/') === 0 || appKeys.some(function (key) { return current.searchParams.has(key); });
  var isInstalled = (window.matchMedia && window.matchMedia('(display-mode: standalone)').matches) || window.navigator.standalone === true;
  if (isAppLink || isInstalled || isCheckoutReturn) {
    var app = new URL('/app.html', current.origin);
    app.search = current.search;
    app.hash = current.hash.indexOf('#/') === 0 ? current.hash : (isCheckoutReturn ? '#/monetisation' : current.hash);
    window.location.replace(app.href);
    return;
  }
  // Preserve Firebase Messaging; remove only the old Flutter app-cache worker.
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations().then(function (registrations) {
      registrations.forEach(function (registration) {
        var worker = registration.active || registration.waiting || registration.installing;
        if (worker && /\/flutter_service_worker\.js(?:\?|$)/i.test(worker.scriptURL)) registration.unregister();
      });
    }).catch(function () { /* Content remains usable without worker cleanup. */ });
  }
}());
