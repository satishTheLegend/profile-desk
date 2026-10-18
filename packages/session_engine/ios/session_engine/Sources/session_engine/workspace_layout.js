/*
 * Profile Desk's bounded presentation adapter. Install in a dedicated isolated
 * JavaScript world, main frame only. It has no native message handler and reads
 * no service content. These structural hooks still require real-service QA.
 */
(() => {
  'use strict';
  const key = '__profileDeskLayout';
  const rootClass = 'profile-desk-phone-layout';
  const detailClass = 'profile-desk-phone-detail';
  const marks = {
    shell: 'profile-desk-layout-shell',
    side: 'profile-desk-layout-side',
    pane: 'profile-desk-layout-pane',
    main: 'profile-desk-layout-main',
    rail: 'profile-desk-layout-rail',
    overlay: 'profile-desk-layout-overlay',
    overlayHost: 'profile-desk-layout-overlay-host',
    overlayFit: 'profile-desk-layout-overlay-fit',
  };
  const allowedOrigin = () => window === window.top &&
    location.protocol === 'https:' && location.hostname === 'web.whatsapp.com' &&
    (location.port === '' || location.port === '443');

  // Re-injection first releases only the previous adapter's own modifications.
  if (globalThis[key] && typeof globalThis[key].dispose === 'function') {
    globalThis[key].dispose();
  }
  if (!allowedOrigin()) return;

  let requestedMode = 'original';
  let state = 'original';
  let reason = null;
  let disposed = false;
  let hooks = null;
  let style = null;
  let observer = null;
  let frame = null;
  let pendingSelection = false;
  let selectionTimer = null;
  let viewport = null;
  const phoneViewport = 'width=device-width, initial-scale=1';
  const ownedMarks = new Map();
  const overlaySelector = '[role="dialog"],[role="alertdialog"],[aria-modal="true"],dialog[open],[role="menu"]';
  const observation = { childList: true, subtree: true, attributes: true,
    attributeFilter: ['id', 'hidden', 'aria-hidden', 'role', 'aria-modal', 'open', 'class', 'style'] };
  const status = () => Object.freeze({
    mode: requestedMode,
    state,
    available: hooks !== null,
    reason,
  });

  const css = `
html.${rootClass}, html.${rootClass} body {
  width:100% !important; min-width:0 !important; max-width:100% !important;
  height:100% !important; overflow:hidden !important;
}
html.${rootClass} .${marks.shell} {
  position:fixed !important; inset:0 !important; width:100% !important;
  height:100% !important; min-width:0 !important; max-width:none !important;
  margin:0 !important; padding:0 !important; border:0 !important;
  transform:none !important; overflow:visible !important;
}
html.${rootClass} .${marks.side} {
  position:absolute !important; top:0 !important; bottom:0 !important;
  left:var(--profile-desk-rail-width, 0px) !important; right:0 !important;
  width:calc(100% - var(--profile-desk-rail-width, 0px)) !important;
  height:100% !important; min-width:0 !important; max-width:none !important;
  margin:0 !important; box-sizing:border-box !important;
  display:flex !important; flex-direction:column !important;
  visibility:visible !important; pointer-events:auto !important;
  transform:none !important; z-index:1 !important;
}
html.${rootClass} .${marks.pane} {
  min-width:0 !important; max-width:100% !important; width:100% !important;
  min-height:0 !important; flex:1 1 auto !important;
  box-sizing:border-box !important; overflow-y:auto !important;
}
html.${rootClass} .${marks.rail} {
  position:absolute !important; left:0 !important; top:0 !important;
  bottom:0 !important; width:var(--profile-desk-rail-width) !important;
  min-width:0 !important; height:100% !important; margin:0 !important;
  visibility:visible !important; pointer-events:auto !important;
  transform:none !important; z-index:2 !important;
}
html.${rootClass} .${marks.main} {
  position:absolute !important; inset:0 !important; width:100% !important;
  height:100% !important; min-width:0 !important; max-width:none !important;
  margin:0 !important; box-sizing:border-box !important;
  transform:none !important; visibility:hidden !important;
  pointer-events:none !important; z-index:0 !important;
}
html.${rootClass} .${marks.side} > *,
html.${rootClass} .${marks.main} > * {
  min-width:0 !important; max-width:100% !important;
}
html.${rootClass} .${marks.side} img,
html.${rootClass} .${marks.side} video {
  max-width:100% !important; height:auto !important;
}
html.${rootClass}.${detailClass} .${marks.main} {
  visibility:visible !important; pointer-events:auto !important; z-index:3 !important;
}
html.${rootClass}.${detailClass} .${marks.side},
html.${rootClass}.${detailClass} .${marks.rail} {
  visibility:hidden !important; pointer-events:none !important;
}
html.${rootClass} [role="dialog"], html.${rootClass} [role="alertdialog"],
html.${rootClass} [aria-modal="true"], html.${rootClass} dialog[open],
html.${rootClass} [role="menu"] {
  max-width:calc(100vw - 24px) !important;
  max-height:calc(100dvh - 24px) !important;
  box-sizing:border-box !important;
  z-index:2147483000 !important;
}
html.${rootClass} .${marks.overlayHost} {
  z-index:2147482999 !important; overflow:visible !important;
}
html.${rootClass} .${marks.overlay} {
  visibility:visible !important; pointer-events:auto !important;
  overflow:auto !important;
}
html.${rootClass} .${marks.overlayFit} {
  position:fixed !important; left:12px !important; top:12px !important;
  right:auto !important; bottom:auto !important; margin:0 !important;
  transform:none !important;
}
/* Presentation changes are immediate, including with reduced motion enabled. */
html.${rootClass} .${marks.shell}, html.${rootClass} .${marks.side},
html.${rootClass} .${marks.main}, html.${rootClass} .${marks.rail} {
  transition:none !important; animation:none !important;
}
`;

  function addMark(element, name) {
    if (!element.classList.contains(name)) {
      element.classList.add(name);
      const names = ownedMarks.get(element) || [];
      names.push(name);
      ownedMarks.set(element, names);
    }
  }

  function clearPresentation() {
    for (const [element, names] of ownedMarks) {
      for (const name of names) element.classList.remove(name);
    }
    ownedMarks.clear();
    if (style) style.remove();
    style = null;
    hooks = null;
  }

  function restoreViewport() {
    if (!viewport) return;
    if (viewport.created) viewport.element.remove();
    // Do not overwrite a later change made by the service itself.
    else if (viewport.element.getAttribute('content') === phoneViewport) {
      if (viewport.content === null) viewport.element.removeAttribute('content');
      else viewport.element.setAttribute('content', viewport.content);
    }
    viewport = null;
  }

  function prepareViewport() {
    if (viewport && viewport.element.isConnected &&
        viewport.element.getAttribute('content') === phoneViewport) return true;
    restoreViewport();
    const metas = document.querySelectorAll('meta[name="viewport" i]');
    if (metas.length > 1) return false;
    const element = metas.length === 1 ? metas[0] : document.createElement('meta');
    // This is the only service attribute value read: nonprivate layout config,
    // retained solely for exact restoration. It never leaves the script.
    viewport = { element, created: metas.length === 0, content: element.getAttribute('content') };
    if (viewport.created) element.setAttribute('name', 'viewport');
    element.setAttribute('content', phoneViewport);
    if (viewport.created) (document.head || document.documentElement).appendChild(element);
    return true;
  }

  function stopSelection() {
    pendingSelection = false;
    if (selectionTimer !== null) clearTimeout(selectionTimer);
    selectionTimer = null;
  }

  function unique(selector) {
    const elements = document.querySelectorAll(selector);
    return elements.length === 1 ? elements[0] : null;
  }

  function usableContainer(element) {
    return element && element !== document.body &&
      element !== document.documentElement && element.isConnected;
  }

  function sharedContainer(side, main) {
    if (!main) return usableContainer(side.parentElement) ? side.parentElement : null;
    let ancestor = side.parentElement;
    for (let depth = 0; depth < 6 && usableContainer(ancestor); depth += 1) {
      if (ancestor.contains(main)) return ancestor;
      ancestor = ancestor.parentElement;
    }
    return null;
  }

  function branch(container, element) {
    let current = element;
    for (let depth = 0; depth < 6 && current && current !== container; depth += 1) {
      if (current.parentElement === container) return current;
      current = current.parentElement;
    }
    return null;
  }

  function findRail(shell, side, detailBranch, viewportHeight) {
    const candidates = Array.from(shell.children).filter((child) => {
      if (child === side || child === detailBranch ||
          child.matches('[role="dialog"],[role="alertdialog"],[aria-modal="true"],[role="menu"],dialog')) return false;
      const rect = child.getBoundingClientRect();
      const semantic = child.matches('nav,[role="navigation"],[role="tablist"]');
      return rect.width >= 32 && rect.width <= 96 &&
        (semantic || rect.height >= viewportHeight * 0.6);
    });
    if (candidates.length > 1) return { failure: 'rail-hook' };
    const rail = candidates[0] || null;
    const railWidth = rail ? Math.round(rail.getBoundingClientRect().width) : 0;
    return { rail, railWidth };
  }

  function inspectStructure(requirePhoneWidth = true, retained = null) {
    if (!allowedOrigin()) return { failure: 'origin' };
    // On mobile, innerWidth can include a desktop child's overflow before our
    // CSS is installed. The root client box represents the layout viewport.
    const viewportWidth = document.documentElement.clientWidth;
    const viewportHeight = document.documentElement.clientHeight;
    if (requirePhoneWidth && (viewportWidth < 320 || viewportWidth > 600)) return { failure: 'width' };
    const panes = document.querySelectorAll('#pane-side');
    const pane = panes.length === 1 ? panes[0] : null;
    if (!pane) {
      // The service can replace a list with its settings/profile/search panel.
      // Retain only the exact side/container already validated in this document;
      // an unfamiliar preauthentication or replacement hierarchy never opts in.
      if (panes.length !== 0 || !retained || !retained.side.isConnected ||
          !retained.shell.isConnected || retained.side.parentElement !== retained.shell ||
          unique('#side') !== retained.side ||
          (retained.rail && (!retained.rail.isConnected || retained.rail.parentElement !== retained.shell))) {
        return { failure: 'list-hook' };
      }
      const mains = document.querySelectorAll('#main');
      if (mains.length > 1 || (mains.length === 1 && mains[0].parentElement !== retained.shell)) {
        return { failure: 'detail-hook' };
      }
      const main = mains.length === 1 ? mains[0] : null;
      const rail = findRail(retained.shell, retained.side, main, viewportHeight);
      if (rail.failure || rail.rail !== retained.rail) return { failure: 'rail-hook' };
      return { pane: null, side: retained.side, main, shell: retained.shell, ...rail };
    }
    const sides = document.querySelectorAll('#side');
    if (sides.length > 1 || (sides.length === 1 && !sides[0].contains(pane))) {
      return { failure: 'side-hook' };
    }
    const mains = document.querySelectorAll('#main');
    if (mains.length > 1) return { failure: 'detail-hook' };
    const main = mains.length === 1 ? mains[0] : null;
    if (main && (pane.contains(main) || main.contains(pane))) return { failure: 'hierarchy' };
    const candidateSide = sides.length === 1 ? sides[0] : pane;
    const shell = sharedContainer(candidateSide, main);
    if (!shell) return { failure: 'container-hook' };
    const side = branch(shell, candidateSide);
    const detailBranch = main ? branch(shell, main) : null;
    if (!side || (main && (!detailBranch || side === detailBranch))) {
      return { failure: 'hierarchy' };
    }
    // An unknown positioned wrapper could establish a different containing
    // block. Leave that layout untouched rather than guessing its geometry.
    if ((sides.length === 1 && side !== candidateSide) ||
        (main && main !== detailBranch)) return { failure: 'container-hook' };
    // Without #side, a common parent must identify a separate list branch.
    if (sides.length === 0 && (!main || side === pane)) return { failure: 'side-hook' };
    const rail = findRail(shell, side, detailBranch, viewportHeight);
    if (rail.failure) return rail;
    return { pane, side, main, shell, ...rail };
  }

  function refresh() {
    frame = null;
    if (disposed || requestedMode !== 'phone') return;
    // Own class/style/viewport mutations must never schedule another refresh.
    // JS runs synchronously here, so service mutations cannot interleave.
    if (observer) observer.disconnect();
    try { refreshPresentation(); }
    finally { if (observer) observer.observe(document.documentElement, observation); }
  }

  function refreshPresentation() {
    // Remove our geometry before validating the service's structural layout.
    const previousState = state;
    const previousHooks = hooks;
    clearPresentation();
    const visual = window.visualViewport;
    const presentedWidth = visual ? visual.width * visual.scale : document.documentElement.clientWidth;
    if (!Number.isFinite(presentedWidth) || presentedWidth < 319 || presentedWidth > 601) {
      restoreViewport();
      state = 'unavailable';
      reason = 'width';
      stopSelection();
      return;
    }
    // Missing/ambiguous service structures must remain completely untouched,
    // including their viewport metadata. Only recognized structures opt in.
    const structural = inspectStructure(false, previousHooks);
    if (structural.failure || !prepareViewport()) {
      restoreViewport();
      state = 'unavailable';
      reason = structural.failure || 'viewport-hook';
      stopSelection();
      return;
    }
    const found = inspectStructure(true, previousHooks);
    if (found.failure) {
      restoreViewport();
      state = 'unavailable';
      reason = found.failure;
      stopSelection();
      return;
    }
    hooks = found;
    // Inspect visibility with our presentation removed. Never expose a dialog
    // the service itself has hidden. Only bounded semantic overlays opt in.
    const overlays = Array.from(document.querySelectorAll(overlaySelector)).slice(0, 16)
      .filter((element) => !element.closest('[hidden],[aria-hidden="true"]') &&
        element.getClientRects().length > 0 && getComputedStyle(element).visibility === 'visible');
    reason = null;
    state = !hooks.pane ? 'menu' :
      (pendingSelection || previousState === 'detail') && hooks.main ? 'detail' : 'list';
    if (state === 'menu') stopSelection();
    if (state === 'detail') stopSelection();
    style = document.createElement('style');
    style.setAttribute('data-profile-desk-layout', '1');
    // The only style data is a clamped native layout measurement, never content.
    style.appendChild(document.createTextNode(css +
      `html.${rootClass} { --profile-desk-rail-width:${hooks.railWidth}px; }`));
    (document.head || document.documentElement).appendChild(style);
    addMark(document.documentElement, rootClass);
    if (state === 'detail') addMark(document.documentElement, detailClass);
    for (const name of ['shell', 'side', 'pane', 'main', 'rail']) {
      if (hooks[name]) addMark(hooks[name], marks[name]);
    }
    for (const element of overlays) {
      addMark(element, marks.overlay);
      let ancestor = element.parentElement;
      for (let depth = 0; depth < 6 && ancestor && ancestor !== hooks.shell &&
           ancestor !== document.body && ancestor !== document.documentElement; depth += 1) {
        addMark(ancestor, marks.overlayHost);
        ancestor = ancestor.parentElement;
      }
      const rect = element.getBoundingClientRect();
      const visualHeight = window.visualViewport?.height || document.documentElement.clientHeight;
      if (rect.left < 0 || rect.right > document.documentElement.clientWidth ||
          rect.top < 0 || rect.bottom > visualHeight) addMark(element, marks.overlayFit);
    }
  }

  function schedule() {
    if (frame === null && !disposed && requestedMode === 'phone') {
      frame = requestAnimationFrame(refresh);
    }
  }

  function onClick(event) {
    if (!event.isTrusted || !hooks || state !== 'list' ||
        !(event.target instanceof Element)) return;
    if (event.target.closest('[role="dialog"],[role="alertdialog"],[role="menu"],[aria-modal="true"],dialog')) return;
    const row = event.target.closest('[role="row"],[role="listitem"]');
    if (!row || !hooks.pane || !hooks.pane.contains(row)) return;
    const interactive = event.target.closest('button,a,input,textarea,select,[contenteditable="true"],[role="button"],[role="textbox"],[role="searchbox"],[role="menuitem"],[role="checkbox"],[role="switch"]');
    if (interactive && row.contains(interactive)) {
      // A single full-row button is a primary activation target. Small nested
      // buttons and explicit popup controls remain service-owned accessories.
      const rowRect = row.getBoundingClientRect();
      const buttonRect = interactive.getBoundingClientRect();
      const primary = interactive.matches('button,[role="button"]') &&
        !interactive.matches('[aria-haspopup]:not([aria-haspopup="false"])') &&
        (interactive === row || (interactive.parentElement === row &&
          row.querySelectorAll('button,[role="button"]').length === 1 &&
          buttonRect.width >= rowRect.width * 0.85 && buttonRect.height >= rowRect.height * 0.85));
      if (!primary) return;
    }
    pendingSelection = true;
    if (selectionTimer !== null) clearTimeout(selectionTimer);
    selectionTimer = setTimeout(() => { stopSelection(); }, 1500);
    // Browser/service handlers receive the original event unchanged. The next
    // frame observes only whether a structural detail container now exists.
    schedule();
  }

  function startObserving() {
    if (observer) return;
    observer = new MutationObserver((records) => {
      if (!hooks || (hooks.pane && !hooks.pane.isConnected) ||
          (!hooks.pane && document.querySelector('#pane-side')) || !hooks.side.isConnected ||
          !hooks.shell.isConnected || (hooks.main && !hooks.main.isConnected) ||
          (hooks.rail && !hooks.rail.isConnected) ||
          (!hooks.main && pendingSelection && document.querySelector('#main')) ||
          records.some((record) => {
            const target = record.target;
            if (!(target instanceof Element)) return false;
            if (record.type === 'attributes') return ownedMarks.has(target) ||
              target.matches('#side,#pane-side,#main,' + overlaySelector) || target.querySelector(overlaySelector) ||
              Object.values(hooks).some((element) => element instanceof Element &&
                (target === element || target.contains(element)));
            return Array.from(record.addedNodes).concat(Array.from(record.removedNodes)).some((node) =>
              node instanceof Element && (node.matches('#side,#pane-side,#main,' + overlaySelector) ||
                node.querySelector('#side,#pane-side,#main,' + overlaySelector)));
          })) schedule();
    });
    observer.observe(document.documentElement, observation);
    document.addEventListener('click', onClick, true);
    window.addEventListener('resize', schedule);
    window.visualViewport?.addEventListener('resize', schedule);
  }

  function stopObserving() {
    if (observer) observer.disconnect();
    observer = null;
    document.removeEventListener('click', onClick, true);
    window.removeEventListener('resize', schedule);
    window.visualViewport?.removeEventListener('resize', schedule);
    if (frame !== null) cancelAnimationFrame(frame);
    frame = null;
    stopSelection();
  }

  const api = Object.freeze({
    setMode(mode) {
      if (disposed || !allowedOrigin()) return Object.freeze({ mode: 'original', state: 'unavailable', available: false, reason: 'origin' });
      if (mode !== 'phone' && mode !== 'original') return status();
      if (mode === 'phone' && requestedMode === 'phone' && hooks) {
        refresh();
        return status();
      }
      requestedMode = mode;
      stopObserving();
      clearPresentation();
      restoreViewport();
      state = mode === 'phone' ? 'list' : 'original';
      reason = null;
      if (mode === 'phone') {
        refresh();
        startObserving();
      }
      return status();
    },
    supportsStructure() {
      return !disposed && !inspectStructure(false, hooks).failure &&
        document.querySelectorAll('meta[name="viewport" i]').length <= 1;
    },
    presentation() {
      if (disposed || !allowedOrigin()) return Object.freeze({ mode: 'original', state: 'unavailable', available: false, reason: 'origin' });
      return status();
    },
    showList() {
      if (disposed || requestedMode !== 'phone') return status();
      stopSelection();
      state = 'list';
      refresh();
      return status();
    },
    dispose() {
      stopObserving();
      clearPresentation();
      restoreViewport();
      requestedMode = 'original';
      state = 'original';
      reason = null;
      disposed = true;
      if (globalThis[key] === api) delete globalThis[key];
      return status();
    },
  });
  Object.defineProperty(globalThis, key, { configurable: true, value: api });
})();
