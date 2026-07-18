(function () {
  'use strict';

  const VERSION_URL = '/version.json';
  const CHECK_INTERVAL_MS = 60000;
  const RELOAD_DELAY_MS = 1800;
  const HOLD_KEY = 'uag-update-hold';
  const LAST_RELOAD_KEY = 'uag-update-last-reload';

  let loadedBuildId = null;
  let pendingVersion = null;
  let updateStarted = false;
  let timer = null;

  function isHeld() {
    return window.localStorage.getItem(HOLD_KEY) === 'true';
  }

  function setCriticalFlowActive(active) {
    if (active) {
      window.localStorage.setItem(HOLD_KEY, 'true');
      return;
    }

    window.localStorage.removeItem(HOLD_KEY);
    if (pendingVersion) {
      applyUpdate(pendingVersion);
    }
  }

  function ensureOverlay() {
    let overlay = document.getElementById('uag-update-overlay');
    if (overlay) return overlay;

    overlay = document.createElement('div');
    overlay.id = 'uag-update-overlay';
    overlay.setAttribute('role', 'status');
    overlay.setAttribute('aria-live', 'polite');
    overlay.innerHTML = `
      <div class="uag-update-panel">
        <div class="uag-update-kicker">UAG SYSTEM UPDATE</div>
        <div class="uag-update-title">Installing the latest build…</div>
        <div class="uag-update-copy">Your session will resume automatically.</div>
        <div class="uag-update-line"><span></span></div>
      </div>`;

    const style = document.createElement('style');
    style.id = 'uag-update-overlay-style';
    style.textContent = `
      #uag-update-overlay {
        position: fixed;
        inset: 0;
        z-index: 2147483647;
        display: grid;
        place-items: center;
        padding: 24px;
        background: rgba(4, 5, 18, 0.82);
        backdrop-filter: blur(8px);
        -webkit-backdrop-filter: blur(8px);
        color: #ecfbff;
        font-family: Arial, Helvetica, sans-serif;
      }
      #uag-update-overlay .uag-update-panel {
        width: min(460px, calc(100vw - 48px));
        padding: 22px 24px;
        border: 1px solid rgba(0, 238, 255, 0.8);
        border-radius: 16px;
        background: rgba(8, 12, 29, 0.96);
        box-shadow: 0 0 28px rgba(0, 238, 255, 0.2);
      }
      #uag-update-overlay .uag-update-kicker {
        color: #00eaff;
        font-size: 12px;
        font-weight: 800;
        letter-spacing: 0.18em;
      }
      #uag-update-overlay .uag-update-title {
        margin-top: 8px;
        font-size: 20px;
        font-weight: 800;
      }
      #uag-update-overlay .uag-update-copy {
        margin-top: 7px;
        color: rgba(236, 251, 255, 0.72);
        font-size: 13px;
      }
      #uag-update-overlay .uag-update-line {
        height: 3px;
        margin-top: 18px;
        overflow: hidden;
        border-radius: 999px;
        background: rgba(255, 255, 255, 0.08);
      }
      #uag-update-overlay .uag-update-line span {
        display: block;
        width: 36%;
        height: 100%;
        border-radius: inherit;
        background: linear-gradient(90deg, #00eaff, #ff3bc8);
        animation: uag-update-scan 1.05s ease-in-out infinite;
      }
      @keyframes uag-update-scan {
        from { transform: translateX(-120%); }
        to { transform: translateX(380%); }
      }
      @media (prefers-reduced-motion: reduce) {
        #uag-update-overlay .uag-update-line span { animation: none; width: 100%; }
      }
    `;

    document.head.appendChild(style);
    document.body.appendChild(overlay);
    return overlay;
  }

  async function fetchVersion() {
    const separator = VERSION_URL.includes('?') ? '&' : '?';
    const response = await fetch(
      `${VERSION_URL}${separator}t=${Date.now()}`,
      {
        cache: 'no-store',
        credentials: 'same-origin',
        headers: { 'Cache-Control': 'no-cache' },
      },
    );

    if (!response.ok) {
      throw new Error(`Version request failed: ${response.status}`);
    }

    const version = await response.json();
    if (!version || typeof version.buildId !== 'string' || !version.buildId.trim()) {
      throw new Error('version.json does not contain a valid buildId');
    }

    return version;
  }

  function applyUpdate(version) {
    if (updateStarted) return;

    if (isHeld()) {
      pendingVersion = version;
      window.dispatchEvent(
        new CustomEvent('uag-update-deferred', { detail: version }),
      );
      return;
    }

    updateStarted = true;
    pendingVersion = null;
    ensureOverlay();
    window.dispatchEvent(new CustomEvent('uag-update-ready', { detail: version }));

    window.setTimeout(function () {
      window.sessionStorage.setItem(
        LAST_RELOAD_KEY,
        JSON.stringify({ buildId: version.buildId, at: Date.now() }),
      );
      window.location.reload();
    }, RELOAD_DELAY_MS);
  }

  async function checkForUpdate() {
    if (updateStarted) return;

    try {
      const version = await fetchVersion();

      if (!loadedBuildId) {
        loadedBuildId = version.buildId;
        window.__UAG_LOADED_BUILD_ID__ = loadedBuildId;
        return;
      }

      if (version.buildId !== loadedBuildId) {
        applyUpdate(version);
      }
    } catch (error) {
      console.debug('[UAG update check]', error);
    }
  }

  async function removeLegacyFlutterServiceWorkers() {
    if (!('serviceWorker' in navigator)) return false;

    try {
      const registrations = await navigator.serviceWorker.getRegistrations();
      let removed = false;
      for (const registration of registrations) {
        if (registration.scope.startsWith(window.location.origin)) {
          removed = (await registration.unregister()) || removed;
        }
      }

      if ('caches' in window) {
        const cacheNames = await caches.keys();
        for (const cacheName of cacheNames) {
          if (/flutter|uag/i.test(cacheName)) {
            await caches.delete(cacheName);
          }
        }
      }
      return removed;
    } catch (error) {
      console.debug('[UAG service worker cleanup]', error);
      return false;
    }
  }

  function start() {
    checkForUpdate();
    timer = window.setInterval(checkForUpdate, CHECK_INTERVAL_MS);

    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'visible') checkForUpdate();
    });
    window.addEventListener('focus', checkForUpdate);
    window.addEventListener('online', checkForUpdate);
  }

  window.UAGUpdateManager = Object.freeze({
    checkNow: checkForUpdate,
    setCriticalFlowActive,
    isCriticalFlowActive: isHeld,
    getLoadedBuildId: function () { return loadedBuildId; },
  });

  window.addEventListener('load', async function () {
    await removeLegacyFlutterServiceWorkers();
    start();
  }, { once: true });
})();
