(() => {
  const video = document.querySelector("#hero-gameplay");
  const toggle = document.querySelector("#hero-video-toggle");

  if (!video || !toggle) return;

  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
  const saveData = navigator.connection?.saveData === true;
  let visible = true;
  let userPaused = false;
  let userStarted = false;

  const updateToggle = () => {
    const paused = video.paused;
    toggle.setAttribute("aria-label", paused ? "Play gameplay video" : "Pause gameplay video");
    toggle.firstElementChild.textContent = paused ? "▶" : "Ⅱ";
  };

  const updatePlayback = () => {
    const automaticPlaybackAllowed = !reducedMotion.matches && !saveData;

    if ((automaticPlaybackAllowed && visible && !userPaused) || (userStarted && visible)) {
      video.play().catch(() => {
        // The poster remains visible when a browser blocks playback.
      });
    } else {
      video.pause();
    }
  };

  if ("IntersectionObserver" in window) {
    const observer = new IntersectionObserver(
      ([entry]) => {
        visible = entry.isIntersecting;
        updatePlayback();
      },
      { threshold: 0.2 }
    );

    observer.observe(video);
  }

  reducedMotion.addEventListener?.("change", updatePlayback);
  video.addEventListener("play", updateToggle);
  video.addEventListener("pause", updateToggle);
  toggle.addEventListener("click", () => {
    if (video.paused) {
      userPaused = false;
      userStarted = true;
    } else {
      userPaused = true;
      userStarted = false;
    }
    updatePlayback();
  });
  updateToggle();
  updatePlayback();
})();
