document.addEventListener("click", (e) => {
  const btn = e.target.closest("[data-dropdown]");
  const menus = document.querySelectorAll("[data-dropdown-menu]");

  if (!btn) {
    menus.forEach((m) => (m.style.display = "none"));
    return;
  }

  const key = btn.getAttribute("data-dropdown");
  const menu = document.querySelector(`[data-dropdown-menu="${key}"]`);
  if (!menu) return;

  const isOpen = menu.style.display === "block";
  menus.forEach((m) => (m.style.display = "none"));
  menu.style.display = isOpen ? "none" : "block";
});

// Date + required validation for search forms (Home + Rooms)
document.addEventListener("DOMContentLoaded", () => {
  const MSG_REQUIRED = "Vui lòng điền đầy đủ thông tin.";
  const MSG_DATE_ORDER = "Ngày đi phải sau ngày đến!";
  const today = new Date().toISOString().split("T")[0];

  document.querySelectorAll("form.rh-search").forEach((form) => {
    const checkIn = form.querySelector('input[name="checkIn"]');
    const checkOut = form.querySelector('input[name="checkOut"]');
    const guests = form.querySelector('select[name="guests"]');
    if (!checkIn || !checkOut || !guests) return;

    // min date = today
    checkIn.setAttribute("min", today);
    checkOut.setAttribute("min", today);

    function syncRequired() {
      checkIn.setCustomValidity(checkIn.value ? "" : MSG_REQUIRED);
      checkOut.setCustomValidity(checkOut.value ? "" : MSG_REQUIRED);
      guests.setCustomValidity(guests.value ? "" : MSG_REQUIRED);
    }

    function syncCheckoutMin() {
      const ci = checkIn.value;
      if (!ci) {
        checkOut.setAttribute("min", today);
        return;
      }
      const nextDay = new Date(ci);
      nextDay.setDate(nextDay.getDate() + 1);
      const minCO = nextDay.toISOString().split("T")[0];
      checkOut.setAttribute("min", minCO);

      if (checkOut.value && checkOut.value <= ci) {
        checkOut.value = "";
      }
    }

    checkIn.addEventListener("change", () => {
      syncCheckoutMin();
      syncRequired();
    });

    checkOut.addEventListener("change", () => {
      const ci = checkIn.value;
      const co = checkOut.value;
      if (ci && co && co <= ci) {
        alert(MSG_DATE_ORDER);
        checkOut.value = "";
      }
      syncRequired();
    });

    ["input", "change"].forEach((ev) => {
      checkIn.addEventListener(ev, syncRequired);
      checkOut.addEventListener(ev, syncRequired);
      guests.addEventListener(ev, syncRequired);
    });

    form.addEventListener("submit", (e) => {
      syncCheckoutMin();
      syncRequired();
      if (!form.checkValidity()) {
        e.preventDefault();
        form.reportValidity(); // hiện đúng MSG_REQUIRED
      }
    });
  });
});

// Scroll to top button
document.addEventListener("DOMContentLoaded", () => {
  const scrollTopBtn = document.getElementById("rhScrollTopBtn");
  if (!scrollTopBtn) return;

  const root = document.scrollingElement || document.documentElement;

  function updateScrollTopVisibility() {
    const viewportHeight = window.innerHeight;
    const scrollableHeight = Math.max(0, root.scrollHeight - viewportHeight);
    const isLongPage = root.scrollHeight > viewportHeight * 1.35;
    const passedHalfScrollable =
      scrollableHeight > 0 && root.scrollTop > scrollableHeight / 2;

    if (isLongPage && passedHalfScrollable) {
      scrollTopBtn.classList.add("is-visible");
    } else {
      scrollTopBtn.classList.remove("is-visible");
    }
  }

  scrollTopBtn.addEventListener("click", () => {
    window.scrollTo({
      top: 0,
      behavior: "smooth",
    });
  });

  window.addEventListener("scroll", updateScrollTopVisibility, {
    passive: true,
  });
  window.addEventListener("resize", updateScrollTopVisibility);
  updateScrollTopVisibility();
});
