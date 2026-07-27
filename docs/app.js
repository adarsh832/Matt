document.addEventListener('DOMContentLoaded', () => {
    // Initialize all site features on DOM load
    initMobileNav();
    initScrollSpyAndNavigation();
    initMenuGroups();
    initOSTabs();
    initClipboard();
    initStepper();
    initSearch();
    initScrollToTop();
});

/**
 * 1. Sidebar Navigation & Smooth Scrolling
 */
function initScrollSpyAndNavigation() {
    const navLinks = document.querySelectorAll('.nav-link[data-section]');
    const tocLinks = document.querySelectorAll('.toc-link[data-section]');
    const sections = document.querySelectorAll('.doc-section');
    const mobileOverlay = document.querySelector('.mobile-nav-overlay');

    // Smooth scroll navigation
    const handleNavClick = (e) => {
        e.preventDefault();
        const targetId = e.currentTarget.getAttribute('data-section');
        const targetSection = document.getElementById(targetId);
        
        if (targetSection) {
            targetSection.scrollIntoView({ behavior: 'smooth' });
        }

        // Close mobile nav on click if open
        if (mobileOverlay && mobileOverlay.classList.contains('open')) {
            mobileOverlay.classList.remove('open');
            document.body.style.overflow = '';
        }
    };

    navLinks.forEach(link => link.addEventListener('click', handleNavClick));
    tocLinks.forEach(link => link.addEventListener('click', handleNavClick));

    // Intersection Observer for scroll spy
    const observerOptions = {
        threshold: 0.2,
        rootMargin: '-64px 0px -60% 0px'
    };

    const sectionObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const id = entry.target.id;
                
                // Update active states
                navLinks.forEach(link => {
                    link.classList.toggle('active', link.getAttribute('data-section') === id);
                });
                
                tocLinks.forEach(link => {
                    link.classList.toggle('active', link.getAttribute('data-section') === id);
                });
            }
        });
    }, observerOptions);

    sections.forEach(section => sectionObserver.observe(section));
}

/**
 * 2. Mobile Navigation
 */
function initMobileNav() {
    const hamburger = document.querySelector('.hamburger-btn');
    const overlay = document.querySelector('.mobile-nav-overlay');
    const closeBtn = document.querySelector('.mobile-nav-close');
    const mobileNavContent = document.getElementById('mobileNavContent');
    const sidebarNav = document.querySelector('.sidebar-nav');

    if (!hamburger || !overlay) return;

    // Clone sidebar links into mobile drawer
    if (sidebarNav && mobileNavContent && mobileNavContent.children.length === 0) {
        mobileNavContent.innerHTML = sidebarNav.innerHTML;
        // Re-init click handlers for cloned links
        mobileNavContent.querySelectorAll('.nav-link[data-section]').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const targetId = link.getAttribute('data-section');
                const targetSection = document.getElementById(targetId);
                if (targetSection) {
                    targetSection.scrollIntoView({ behavior: 'smooth' });
                }
                toggleNav(false);
            });
        });
        // Re-init accordion triggers in mobile drawer
        mobileNavContent.querySelectorAll('.menu-trigger').forEach(trigger => {
            trigger.addEventListener('click', () => {
                const parentGroup = trigger.closest('.menu-group');
                if (parentGroup) parentGroup.classList.toggle('open');
            });
        });
    }

    const toggleNav = (forceState) => {
        const isOpen = forceState !== undefined ? forceState : !overlay.classList.contains('open');
        overlay.classList.toggle('open', isOpen);
        document.body.style.overflow = isOpen ? 'hidden' : '';
    };

    hamburger.addEventListener('click', () => toggleNav());

    if (closeBtn) {
        closeBtn.addEventListener('click', () => toggleNav(false));
    }

    // Close on backdrop click (not the drawer)
    overlay.addEventListener('click', (e) => {
        if (e.target === overlay) toggleNav(false);
    });

    // Close on Escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && overlay.classList.contains('open')) {
            toggleNav(false);
        }
    });
}

/**
 * 3. Collapsible Menu Groups (Accordion)
 */
function initMenuGroups() {
    const triggers = document.querySelectorAll('.menu-trigger');
    const groups = document.querySelectorAll('.menu-group');

    // Accordion behavior
    triggers.forEach(trigger => {
        trigger.addEventListener('click', (e) => {
            const parentGroup = e.currentTarget.closest('.menu-group');
            
            // Close other groups
            groups.forEach(group => {
                if (group !== parentGroup) {
                    group.classList.remove('open');
                }
            });

            // Toggle current group
            parentGroup.classList.toggle('open');
        });
    });

    // Open group with active link on load, or first group
    const activeLink = document.querySelector('.nav-link.active');
    if (activeLink) {
        const activeGroup = activeLink.closest('.menu-group');
        if (activeGroup) activeGroup.classList.add('open');
    } else if (groups.length > 0) {
        groups[0].classList.add('open');
    }
}

/**
 * 4. OS Tab Switcher
 */
function initOSTabs() {
    const tabs = document.querySelectorAll('.os-tab');
    const contents = document.querySelectorAll('.os-tab-content');
    
    if (tabs.length === 0) return;

    // Detect user OS
    let userOS = 'windows';
    const ua = navigator.userAgent.toLowerCase();
    if (ua.indexOf('mac') !== -1) userOS = 'mac';
    else if (ua.indexOf('linux') !== -1) userOS = 'linux';

    const switchTab = (osName) => {
        tabs.forEach(tab => {
            tab.classList.toggle('active', tab.getAttribute('data-os') === osName);
        });
        contents.forEach(content => {
            const isMatch = content.getAttribute('data-os') === osName;
            content.style.display = isMatch ? 'block' : 'none';
            content.classList.toggle('active', isMatch);
        });
    };

    // Listeners
    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            switchTab(tab.getAttribute('data-os'));
        });
    });

    // Initial activation
    switchTab(userOS);
}

/**
 * 5. Copy to Clipboard
 */
function initClipboard() {
    const copyBtns = document.querySelectorAll('.copy-btn');

    copyBtns.forEach(btn => {
        btn.addEventListener('click', async () => {
            // Navigate: .copy-btn -> .code-header -> .code-wrapper -> .code-block code
            const wrapper = btn.closest('.code-wrapper');
            if (!wrapper) return;
            const codeEl = wrapper.querySelector('.code-block code');
            if (!codeEl) return;

            const text = codeEl.textContent;

            try {
                await navigator.clipboard.writeText(text);
                
                // Success state
                btn.textContent = '✓ Copied';
                btn.classList.add('copied');
                
                setTimeout(() => {
                    btn.textContent = 'Copy';
                    btn.classList.remove('copied');
                }, 2000);
            } catch (err) {
                console.error('Failed to copy text: ', err);
            }
        });
    });
}

/**
 * 6. Interactive Setup Stepper
 */
function initStepper() {
    const steps = document.querySelectorAll('.step');
    const stepBtns = document.querySelectorAll('.step-nav-btn');
    const contentArea = document.querySelector('.step-content-area');
    
    if (steps.length === 0) return;

    // Setup dummy descriptions if a content area is provided
    const stepDescriptions = {
        1: "Start your LM Studio local server. Ensure the server is listening on your local network.",
        2: "Run the Python Gateway script to bridge the connection.",
        3: "Scan the QR code displayed in your terminal with the mobile app to connect instantly."
    };

    const updateStepper = (currentStepIndex) => {
        steps.forEach((step, index) => {
            // Steps are usually 1-indexed in data
            const stepNum = index + 1;
            
            step.classList.remove('active', 'completed');
            if (stepNum === currentStepIndex) {
                step.classList.add('active');
            } else if (stepNum < currentStepIndex) {
                step.classList.add('completed');
            }
        });

        if (contentArea) {
            contentArea.textContent = stepDescriptions[currentStepIndex] || '';
        }
    };

    stepBtns.forEach(btn => {
        btn.addEventListener('click', (e) => {
            const targetStep = parseInt(e.currentTarget.getAttribute('data-step'), 10);
            if (!isNaN(targetStep)) {
                updateStepper(targetStep);
            }
        });
    });

    // Initialize first step
    updateStepper(1);
}

/**
 * 7. Search / Filter
 */
function initSearch() {
    const searchInput = document.querySelector('.search-input');
    const navLinks = document.querySelectorAll('.nav-link');
    const menuGroups = document.querySelectorAll('.menu-group');

    if (!searchInput) return;

    // Filter functionality
    searchInput.addEventListener('input', (e) => {
        const term = e.target.value.toLowerCase();

        navLinks.forEach(link => {
            const text = link.textContent.toLowerCase();
            const isMatch = text.includes(term);
            link.style.display = isMatch ? 'block' : 'none';
        });

        // Hide menu groups if they have no visible links
        menuGroups.forEach(group => {
            const linksInGroup = Array.from(group.querySelectorAll('.nav-link'));
            const hasVisibleLinks = linksInGroup.some(l => l.style.display !== 'none');
            group.style.display = hasVisibleLinks ? 'block' : 'none';
            
            // Auto open if searching
            if (term.trim() !== '' && hasVisibleLinks) {
                group.classList.add('open');
            }
        });
    });

    // Keyboard Shortcuts (Ctrl+K / Cmd+K, Escape)
    document.addEventListener('keydown', (e) => {
        if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
            e.preventDefault();
            searchInput.focus();
        }
        if (e.key === 'Escape' && document.activeElement === searchInput) {
            searchInput.value = '';
            searchInput.blur();
            searchInput.dispatchEvent(new Event('input')); // Trigger reset
        }
    });
}

/**
 * 8. Scroll-to-top button
 */
function initScrollToTop() {
    const btn = document.querySelector('.scroll-top-btn');
    if (!btn) return;

    // Style adjustments for visibility animation
    btn.style.transition = 'opacity 0.3s, transform 0.3s';

    window.addEventListener('scroll', () => {
        if (window.scrollY > 500) {
            btn.style.opacity = '1';
            btn.style.transform = 'translateY(0)';
            btn.style.pointerEvents = 'auto';
        } else {
            btn.style.opacity = '0';
            btn.style.transform = 'translateY(20px)';
            btn.style.pointerEvents = 'none';
        }
    });

    // Initial state trigger
    window.dispatchEvent(new Event('scroll'));

    btn.addEventListener('click', () => {
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });
}
