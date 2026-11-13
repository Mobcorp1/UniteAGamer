/* Retain old path-based app links when Firebase serves the app shell for them. */
(function () {
  'use strict';
  var current = new URL(window.location.href);
  if (current.pathname !== '/app.html' && current.pathname !== '/app') {
    var app = new URL('/app.html', current.origin);
    app.search = current.search;
    app.hash = current.hash.indexOf('#/') === 0 ? current.hash : '#' + current.pathname;
    window.location.replace(app.href);
  }
}());
