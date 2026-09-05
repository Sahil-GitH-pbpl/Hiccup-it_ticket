(() => {
  const appWrapperSelector = ".app-content-wrapper";
  const authLinks = {
    login: document.getElementById("nav-login"),
    logout: document.getElementById("nav-logout"),
  };
  const userLabel = document.getElementById("nav-user-label");
  const navHicAll = document.getElementById("nav-hic-all");
  const navItAll = document.getElementById("nav-it-all");
  const mobileNav = {
    toggle: document.getElementById("mobile-nav-toggle"),
    close: document.getElementById("mobile-nav-close"),
    overlay: document.getElementById("mobile-nav-overlay"),
    drawer: document.getElementById("mobile-nav-drawer"),
    login: document.getElementById("nav-login-mobile"),
    logout: document.getElementById("nav-logout-mobile"),
    user: document.getElementById("nav-user-mobile"),
    hicAll: document.getElementById("nav-hic-all-mobile"),
    itAll: document.getElementById("nav-it-all-mobile"),
  };
  const dropdowns = [
    { toggle: document.getElementById("nav-hiccup-toggle"), menu: document.getElementById("nav-hiccup-menu") },
    { toggle: document.getElementById("nav-it-toggle"), menu: document.getElementById("nav-it-menu") },
  ];
  const getCurrentUser = () => window.currentUser || {};
  const isLoggedIn = () => Boolean(getCurrentUser().user_id);
  const getDesignation = () => (getCurrentUser().designation || "").toString().toLowerCase();

  function toggleAuthLinks() {
    const loggedIn = isLoggedIn();
    authLinks.login?.classList.toggle("hidden", loggedIn);
    authLinks.logout?.classList.toggle("hidden", !loggedIn);
    if (!userLabel) return;
    if (!loggedIn) {
      userLabel.classList.add("hidden");
      userLabel.textContent = "";
      return;
    }
    const { name: username } = getCurrentUser();
    userLabel.textContent = username || "";
    userLabel.classList.toggle("hidden", !username);
  }

  function isAdminLike() {
    if (window.serverIsAdmin) return true;
    if (!isLoggedIn()) return false;
    if (getCurrentUser().is_infra_admin === true || Number(getCurrentUser().user_id) === 95) return true;
    const designation = getDesignation().trim();
    const role = (getCurrentUser().role || "").toString().toLowerCase();
    return ["admin", "it", "infra"].some((key) => designation.includes(key) || role.includes(key));
  }

  function canViewAllHiccups() {
    if (window.serverCanViewAllHiccups) return true;
    if (!isLoggedIn()) return false;
    return getCurrentUser().is_admin_like === true;
  }

  function toggleAllTickets() {
    const hiccupAdmin = canViewAllHiccups();
    const infraAdmin = isAdminLike();
    navHicAll?.classList.toggle("hidden", !hiccupAdmin);
    mobileNav.hicAll?.classList.toggle("hidden", !hiccupAdmin);
    navItAll?.classList.toggle("hidden", !infraAdmin);
    mobileNav.itAll?.classList.toggle("hidden", !infraAdmin);
  }

  function toggleMobileAuthLinks() {
    const loggedIn = isLoggedIn();
    mobileNav.login?.classList.toggle("hidden", loggedIn);
    mobileNav.logout?.classList.toggle("hidden", !loggedIn);
    if (!mobileNav.user) return;
    mobileNav.user.textContent = loggedIn ? getCurrentUser().name || "" : "";
    mobileNav.user.classList.toggle("hidden", !loggedIn);
  }

  function closeDropdowns(exceptMenu) {
    dropdowns.forEach(({ menu }) => {
      if (menu && menu !== exceptMenu) menu.classList.add("hidden");
    });
  }

  let pinnedDropdownMenu = null;
  dropdowns.forEach(({ toggle, menu }) => {
    if (!toggle || !menu) return;
    toggle.addEventListener("click", (event) => {
      event.preventDefault();
      pinnedDropdownMenu = menu;
      closeDropdowns(menu);
      menu.classList.remove("hidden");
    });
    const showMenu = () => {
      if (pinnedDropdownMenu && pinnedDropdownMenu !== menu) return;
      closeDropdowns(menu);
      menu.classList.remove("hidden");
    };
    const maybeHideMenu = () => {
      if (pinnedDropdownMenu === menu) return;
      setTimeout(() => {
        if (!toggle.matches(":hover") && !menu.matches(":hover")) menu.classList.add("hidden");
      }, 80);
    };
    toggle.addEventListener("mouseenter", showMenu);
    menu.addEventListener("mouseenter", showMenu);
    toggle.addEventListener("mouseleave", maybeHideMenu);
    menu.addEventListener("mouseleave", maybeHideMenu);
  });

  document.addEventListener("click", (event) => {
    if (!event.target.closest(".nav-dropdown-parent")) {
      pinnedDropdownMenu = null;
      closeDropdowns();
    }
  });

  authLinks.logout?.addEventListener("click", () => logout());
  mobileNav.logout?.addEventListener("click", () => {
    logout();
    closeMobileNav();
  });

  async function hydrateUser() {
    if (isLoggedIn()) return;
    try {
      const res = await fetch("/api/auth/me", { credentials: "same-origin" });
      if (res.ok) {
        const data = await res.json();
        window.currentUser = {
          user_id: data.user_id,
          role: data.role,
          name: data.name,
          department_id: data.department_id,
          designation: data.designation || "",
          is_admin_like: data.is_admin_like === true,
          is_infra_admin: data.is_infra_admin === true,
        };
      }
    } catch (err) {
      console.warn("Failed to hydrate user", err);
    }
  }

  const syncAuthState = () => {
    toggleAuthLinks();
    toggleAllTickets();
    toggleMobileAuthLinks();
  };

  let didInitialHydrate = false;

  function openMobileNav() {
    mobileNav.drawer?.classList.remove("hidden");
    mobileNav.drawer?.classList.add("open");
    mobileNav.overlay?.classList.remove("hidden");
  }

  function closeMobileNav() {
    mobileNav.drawer?.classList.remove("open");
    mobileNav.overlay?.classList.add("hidden");
    setTimeout(() => mobileNav.drawer?.classList.add("hidden"), 200);
  }

  mobileNav.toggle?.addEventListener("click", (event) => {
    event.preventDefault();
    openMobileNav();
  });
  mobileNav.close?.addEventListener("click", (event) => {
    event.preventDefault();
    closeMobileNav();
  });
  mobileNav.overlay?.addEventListener("click", closeMobileNav);
  mobileNav.drawer?.querySelectorAll("a, button").forEach((el) => el.addEventListener("click", closeMobileNav));

  async function bootstrapNavbar() {
    if (didInitialHydrate) return;
    didInitialHydrate = true;
    await hydrateUser();
    syncAuthState();
  }

  document.addEventListener("DOMContentLoaded", bootstrapNavbar);

  const skippedScriptParts = [
    "/static/js/tailwind.js",
    "/static/js/main.js",
    "/static/js/shared-navbar.js",
    "cdn.jsdelivr.net/npm/sweetalert2",
  ];
  const loadedPjaxScripts = new Set(
    Array.from(document.scripts)
      .map((script) => script.src || "")
      .filter(Boolean)
      .map((src) => new URL(src, window.location.origin).pathname)
  );
  const pjaxManagedStylePaths = new Set(
    Array.from(document.querySelectorAll('link[rel="stylesheet"][href]'))
      .filter((link) => !isBaseStylesheet(link))
      .map(stylesheetPath)
      .filter(Boolean)
  );
  document.querySelectorAll('link[rel="stylesheet"][href]').forEach((link) => {
    if (!isBaseStylesheet(link)) link.dataset.pjaxStyle = "true";
  });

  function stylesheetPath(link) {
    const href = link?.getAttribute("href") || "";
    if (!href) return "";
    try {
      return new URL(href, window.location.origin).pathname;
    } catch {
      return href.split("?")[0] || "";
    }
  }

  function isBaseStylesheet(link) {
    const path = stylesheetPath(link);
    return path === "/static/style.css" || path === "/static/css/shared-navbar.css";
  }

  function hasStylesheet(path) {
    return Array.from(document.querySelectorAll('link[rel="stylesheet"][href]')).some(
      (link) => stylesheetPath(link) === path
    );
  }

  async function syncPageStyles(nextDocument) {
    const nextStyles = Array.from(nextDocument.querySelectorAll('link[rel="stylesheet"][href]')).filter(
      (link) => !isBaseStylesheet(link)
    );
    const nextStylePaths = new Set(nextStyles.map(stylesheetPath).filter(Boolean));
    const pendingLoads = [];

    document.querySelectorAll('link[data-pjax-style="true"]').forEach((link) => {
      const path = stylesheetPath(link);
      if (!nextStylePaths.has(path)) {
        pjaxManagedStylePaths.delete(path);
        link.remove();
      }
    });

    nextStyles.forEach((link) => {
      const path = stylesheetPath(link);
      if (!path || pjaxManagedStylePaths.has(path) || hasStylesheet(path)) return;
      const nextLink = document.createElement("link");
      Array.from(link.attributes).forEach((attr) => nextLink.setAttribute(attr.name, attr.value));
      nextLink.dataset.pjaxStyle = "true";
      pendingLoads.push(
        new Promise((resolve) => {
          nextLink.onload = resolve;
          nextLink.onerror = resolve;
          setTimeout(resolve, 1200);
        })
      );
      document.head.appendChild(nextLink);
      pjaxManagedStylePaths.add(path);
    });

    await Promise.all(pendingLoads);
  }

  function normalizePath(src) {
    try {
      return new URL(src, window.location.origin).pathname;
    } catch {
      return src || "";
    }
  }

  function shouldSkipScript(script) {
    const src = script.getAttribute("src") || "";
    if (!src) {
      const text = script.textContent || "";
      return text.includes("tailwind.config") || text.includes("window.currentUser");
    }
    return skippedScriptParts.some((part) => src.includes(part));
  }

  function loadExternalScript(script) {
    const src = script.getAttribute("src");
    if (!src) return Promise.resolve();
    const normalized = normalizePath(src);
    if (loadedPjaxScripts.has(normalized)) return Promise.resolve();

    return new Promise((resolve, reject) => {
      const nextScript = document.createElement("script");
      Array.from(script.attributes).forEach((attr) => nextScript.setAttribute(attr.name, attr.value));
      nextScript.dataset.pjaxScript = "true";
      nextScript.async = false;
      nextScript.onload = () => {
        loadedPjaxScripts.add(normalized);
        resolve();
      };
      nextScript.onerror = reject;
      document.body.appendChild(nextScript);
    });
  }

  function runInlineScript(script) {
    if (!script.textContent?.trim()) return;
    const nextScript = document.createElement("script");
    nextScript.dataset.pjaxScript = "true";
    nextScript.textContent = script.textContent;
    document.body.appendChild(nextScript);
  }

  async function runPageScripts(nextDocument) {
    document.querySelectorAll("script[data-pjax-script]").forEach((script) => script.remove());
    const scripts = Array.from(nextDocument.scripts).filter((script) => !shouldSkipScript(script));

    for (const script of scripts) {
      if (script.src || script.getAttribute("src")) {
        await loadExternalScript(script);
      } else {
        runInlineScript(script);
      }
    }

    document.dispatchEvent(new Event("DOMContentLoaded", { bubbles: true }));
    window.dispatchEvent(new Event("pjax:navigation"));
  }

  function isSafeInternalNavLink(link) {
    if (!link || link.target || link.hasAttribute("download")) return false;
    if (!link.closest("header, #mobile-nav-drawer")) return false;
    if (link.closest("#nav-logout, #nav-logout-mobile")) return false;

    const url = new URL(link.href, window.location.origin);
    if (url.origin !== window.location.origin) return false;
    if (url.pathname === window.location.pathname && url.search === window.location.search) return false;
    if (url.pathname.startsWith("/logout") || url.pathname.startsWith("/login")) return false;
    return true;
  }

  async function navigateWithoutNavbarReload(url, shouldPush = true) {
    const currentWrapper = document.querySelector(appWrapperSelector);
    if (!currentWrapper) {
      window.location.href = url.href;
      return;
    }

    document.documentElement.classList.add("pjax-loading");
    try {
      const response = await fetch(url.href, {
        credentials: "same-origin",
        headers: { "X-Requested-With": "XMLHttpRequest", "X-PJAX": "true" },
      });
      const contentType = response.headers.get("content-type") || "";
      if (!response.ok || !contentType.includes("text/html")) {
        window.location.href = url.href;
        return;
      }

      const html = await response.text();
      const nextDocument = new DOMParser().parseFromString(html, "text/html");
      const nextWrapper = nextDocument.querySelector(appWrapperSelector);
      if (!nextWrapper) {
        window.location.href = url.href;
        return;
      }

      document.title = nextDocument.title || document.title;
      await syncPageStyles(nextDocument);
      currentWrapper.replaceWith(document.importNode(nextWrapper, true));
      window.scrollTo({ top: 0, left: 0, behavior: "instant" });
      closeDropdowns();
      closeMobileNav();
      if (shouldPush) window.history.pushState({}, "", url.href);
      await runPageScripts(nextDocument);
      syncAuthState();
    } catch (err) {
      console.warn("Smooth navigation failed, falling back to page load", err);
      window.location.href = url.href;
    } finally {
      document.documentElement.classList.remove("pjax-loading");
    }
  }

  document.addEventListener("click", (event) => {
    if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    const link = event.target.closest("a[href]");
    if (!isSafeInternalNavLink(link)) return;
    event.preventDefault();
    navigateWithoutNavbarReload(new URL(link.href, window.location.origin));
  });

  window.addEventListener("popstate", () => {
    navigateWithoutNavbarReload(new URL(window.location.href), false);
  });
})();
