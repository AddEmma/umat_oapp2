// Simple download tracking and UX enhancements
document.addEventListener('DOMContentLoaded', function () {
    const downloadBtn = document.getElementById('downloadBtn');

    if (downloadBtn) {
        downloadBtn.addEventListener('click', function (e) {
            // Add click animation
            this.style.transform = 'scale(0.98)';
            setTimeout(() => {
                this.style.transform = '';
            }, 150);

            // Show download started feedback
            const originalText = this.querySelector('.btn-label').textContent;
            this.querySelector('.btn-label').textContent = 'Download Started!';

            setTimeout(() => {
                this.querySelector('.btn-label').textContent = originalText;
            }, 3000);

            // Log download (you can replace this with analytics)
            console.log('APK download initiated at:', new Date().toISOString());
        });
    }

    // Add smooth reveal animations on scroll
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, observerOptions);

    // Observe feature cards and steps
    document.querySelectorAll('.feature-card, .step').forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(20px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
});

// Detect if on mobile and show appropriate messaging
if (/Android/i.test(navigator.userAgent)) {
    console.log('Android device detected - APK can be installed directly');
} else if (/iPhone|iPad|iPod/i.test(navigator.userAgent)) {
    // Show iOS notice
    const downloadBtn = document.getElementById('downloadBtn');
    if (downloadBtn) {
        downloadBtn.innerHTML = `
            <span class="btn-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="12" y1="8" x2="12" y2="12"></line>
                    <line x1="12" y1="16" x2="12.01" y2="16"></line>
                </svg>
            </span>
            <span class="btn-text">
                <span class="btn-label">Android Only</span>
                <span class="btn-size">iOS version coming soon</span>
            </span>
        `;
        downloadBtn.href = '#';
        downloadBtn.onclick = (e) => {
            e.preventDefault();
            alert('This app is currently available for Android only. iOS version coming soon!');
        };
    }
}
