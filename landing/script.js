document.addEventListener('DOMContentLoaded', () => {
    
    // Simple smooth scrolling for nav links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();

            document.querySelector(this.getAttribute('href')).scrollIntoView({
                behavior: 'smooth'
            });
        });
    });

    // Simple interaction on button hover
    const actionBtns = document.querySelectorAll('.action-btn');
    actionBtns.forEach(btn => {
        btn.addEventListener('mouseenter', () => {
            btn.style.transform = 'translate(-2px, -2px)';
            btn.style.boxShadow = '10px 10px 0 var(--border-color)';
        });
        
        btn.addEventListener('mouseleave', () => {
            btn.style.transform = 'translate(0px, 0px)';
            btn.style.boxShadow = '8px 8px 0 var(--border-color)';
        });

        btn.addEventListener('mousedown', () => {
            btn.style.transform = 'translate(8px, 8px)';
            btn.style.boxShadow = '0px 0px 0 var(--border-color)';
        });

        btn.addEventListener('mouseup', () => {
            btn.style.transform = 'translate(-2px, -2px)';
            btn.style.boxShadow = '10px 10px 0 var(--border-color)';
        });
    });

    // Marquee content clone for infinite scrolling
    const marqueeContent = document.querySelector('.marquee-content');
    if (marqueeContent) {
        // Clone to ensure seamless scrolling
        const clone = marqueeContent.cloneNode(true);
        marqueeContent.parentElement.appendChild(clone);
    }
});
