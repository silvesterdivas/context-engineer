// ── Copy to clipboard ──
function copyCode(btn) {
  const code = btn.getAttribute('data-code');
  navigator.clipboard.writeText(code).then(() => {
    btn.textContent = 'Copied!';
    btn.classList.add('copied');
    setTimeout(() => {
      btn.textContent = 'Copy';
      btn.classList.remove('copied');
    }, 2000);
  });
}

// ── Smooth scroll ──
document.querySelectorAll('a[href^="#"]').forEach(a => {
  a.addEventListener('click', e => {
    e.preventDefault();
    const target = document.querySelector(a.getAttribute('href'));
    if (target) target.scrollIntoView({ behavior: 'smooth', block: 'start' });
  });
});

// ── Before/After toggle ──
const beforeAfterTabs = document.querySelectorAll('.before-after__tab');
if (beforeAfterTabs.length) {
  beforeAfterTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      const container = tab.closest('.before-after');
      container.querySelectorAll('.before-after__tab').forEach(t => t.classList.remove('active'));
      container.querySelectorAll('.before-after__panel').forEach(p => p.classList.remove('active'));
      tab.classList.add('active');
      document.getElementById('panel-' + tab.dataset.panel).classList.add('active');
    });
  });
}

// ── Intersection Observer for section reveals ──
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('revealed');
      // Animate savings bars when section 03 comes into view
      if (entry.target.id === 'savings') {
        entry.target.querySelectorAll('.savings-item__fill').forEach((bar, i) => {
          setTimeout(() => {
            bar.style.width = bar.dataset.width + '%';
          }, i * 200);
        });
      }
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.15 });

document.querySelectorAll('.section').forEach(s => observer.observe(s));

// ── Scan line on load ──
window.addEventListener('load', () => {
  setTimeout(() => {
    document.getElementById('scanLine').classList.add('active');
  }, 300);
});
