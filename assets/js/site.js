// Toggle abstract / BibTeX panels and copy BibTeX on the publications page.
document.addEventListener("click", (event) => {
  if (event.target.closest(".theme-toggle")) {
    const root = document.documentElement;
    const dark = root.dataset.theme !== "dark";
    if (dark) root.dataset.theme = "dark";
    else delete root.dataset.theme;
    try { localStorage.setItem("theme", dark ? "dark" : "light"); } catch (e) {}
    return;
  }

  const toggle = event.target.closest("button[aria-controls]");
  if (toggle) {
    const panel = document.getElementById(toggle.getAttribute("aria-controls"));
    const open = toggle.getAttribute("aria-expanded") === "true";
    toggle.setAttribute("aria-expanded", String(!open));
    panel.hidden = open;
    return;
  }

  const copy = event.target.closest("button[data-copy]");
  if (copy) {
    const code = document.getElementById(copy.dataset.copy).querySelector("code");
    navigator.clipboard.writeText(code.textContent).then(() => {
      copy.textContent = "Copied";
      setTimeout(() => (copy.textContent = "Copy"), 1500);
    });
  }
});
