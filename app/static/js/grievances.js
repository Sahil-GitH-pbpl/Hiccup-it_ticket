document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("[data-grievance-toggle]").forEach((button) => {
    button.addEventListener("click", () => {
      const targetId = button.getAttribute("aria-controls");
      const target = document.getElementById(targetId);
      if (!target) return;

      const isOpen = !target.classList.contains("hidden");
      target.classList.toggle("hidden", isOpen);
      button.setAttribute("aria-expanded", String(!isOpen));
      button.querySelector(".grievance-arrow")?.classList.toggle("is-open", !isOpen);
    });
  });
});
