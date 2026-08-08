(function () {
  const now = new Date();
  const month = now.getMonth();
  const day = now.getDate();
  const isIndependenceSeason = month === 7 && day >= 1 && day <= 20;

  if (!isIndependenceSeason) return;
  if (document.body.classList.contains("no-nav")) return;

  document.documentElement.classList.add("independence-theme");
  document.body.classList.add("independence-theme");

  const dismissedKey = "independenceBannerDismissed2026";
  const wrapper = document.querySelector(".app-content-wrapper");

  function createBanner() {
    if (!wrapper || sessionStorage.getItem(dismissedKey) === "1") return;
    if (document.querySelector(".independence-banner")) return;

    const banner = document.createElement("section");
    banner.className = "independence-banner";
    banner.setAttribute("aria-label", "Independence Day theme");
    banner.innerHTML = `
      <div class="independence-banner__inner">
        <div class="independence-banner__copy">
          <div class="independence-emblem" aria-hidden="true">
            <div class="independence-flag">
              <span></span><span></span><span></span>
            </div>
          </div>
          <div>
            <p class="independence-banner__eyebrow">15 August Special</p>
            <h2 class="independence-banner__title">Happy Independence Day</h2>
            <p class="independence-banner__text">Celebrating freedom, service and teamwork.</p>
          </div>
        </div>
        <button class="independence-banner__close" type="button" aria-label="Hide Independence Day banner">Hide</button>
      </div>
    `;

    banner.querySelector(".independence-banner__close")?.addEventListener("click", () => {
      sessionStorage.setItem(dismissedKey, "1");
      banner.remove();
    });

    wrapper.parentNode.insertBefore(banner, wrapper);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => {
      createBanner();
    });
  } else {
    createBanner();
  }
})();
