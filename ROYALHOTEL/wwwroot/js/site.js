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

// Hold to reveal password (Login / Register / Forgot Password)
document.addEventListener("DOMContentLoaded", () => {
  const EYE_OPEN_PATH =
    '<path d="M2 12C3.8 8.8 7.2 6.5 12 6.5C16.8 6.5 20.2 8.8 22 12C20.2 15.2 16.8 17.5 12 17.5C7.2 17.5 3.8 15.2 2 12Z" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>' +
    '<circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="1.8"/>';
  const EYE_SLASH_PATH =
    '<path d="M3 3l18 18M10.5 10.677A3 3 0 0 0 14.47 14.6M6.357 6.5C4.309 7.883 2.863 9.8 2 12c1.8 3.2 5.2 5.5 10 5.5a11.9 11.9 0 0 0 4.638-.937M9.346 4.938A11.9 11.9 0 0 1 12 4.5c4.8 0 8.2 2.3 10 5.5a14.2 14.2 0 0 1-1.646 2.356" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>';

  const controls = [];

  document.querySelectorAll("[data-password-toggle]").forEach((button) => {
    const targetId = button.getAttribute("data-toggle-target");
    if (!targetId) return;

    const input = document.getElementById(targetId);
    if (!input) return;

    const svgEl = button.querySelector("svg");

    const showPassword = () => {
      const start = input.selectionStart ?? input.value.length;
      const end = input.selectionEnd ?? input.value.length;
      input.setAttribute("type", "text");
      setTimeout(() => input.setSelectionRange(start, end), 0);
      button.classList.add("is-pressing");
      button.setAttribute("aria-label", "Thả để ẩn mật khẩu");
      button.setAttribute("aria-pressed", "true");
      if (svgEl) svgEl.innerHTML = EYE_SLASH_PATH;
    };

    const hidePassword = () => {
      const start = input.selectionStart ?? input.value.length;
      const end = input.selectionEnd ?? input.value.length;
      input.setAttribute("type", "password");
      setTimeout(() => input.setSelectionRange(start, end), 0);
      button.classList.remove("is-pressing");
      button.setAttribute("aria-label", "Giữ để xem mật khẩu");
      button.setAttribute("aria-pressed", "false");
      if (svgEl) svgEl.innerHTML = EYE_OPEN_PATH;
    };

    controls.push({ hidePassword });

    button.addEventListener("pointerdown", (e) => {
      e.preventDefault();
      showPassword();
    });

    button.addEventListener("pointerup", hidePassword);
    button.addEventListener("pointerleave", hidePassword);
    button.addEventListener("pointercancel", hidePassword);
    button.addEventListener("blur", hidePassword);

    button.addEventListener("keydown", (e) => {
      if (e.key === " " || e.key === "Enter") {
        e.preventDefault();
        showPassword();
      }
    });

    button.addEventListener("keyup", (e) => {
      if (e.key === " " || e.key === "Enter") {
        e.preventDefault();
        hidePassword();
      }
    });

    // Hide on form submit
    const form = input.closest("form");
    if (form) {
      form.addEventListener("submit", hidePassword);
    }
  });

  document.addEventListener("pointerup", () => {
    controls.forEach((item) => item.hidePassword());
  });

  window.addEventListener("blur", () => {
    controls.forEach((item) => item.hidePassword());
  });

  document.addEventListener("visibilitychange", () => {
    if (document.hidden) {
      controls.forEach((item) => item.hidePassword());
    }
  });
});


