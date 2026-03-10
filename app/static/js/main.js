function authHeaders() {
    const token = window.PUBLIC_TOKEN;
    return token ? { 'Authorization': `Bearer ${token}` } : {};
}

function clearAuthState() {
    document.cookie = 'token=; Max-Age=0; path=/';
}

function showAlert(options = {}) {
    const { title = 'Notice', text = '', icon = 'info', confirmButtonText = 'OK', timer, ...rest } = options;
    if (typeof Swal === 'undefined') {
        if (text || title) {
            alert(`${title}${text ? ` - ${text}` : ''}`);
        }
        return Promise.resolve({ isConfirmed: true });
    }
    return Swal.fire({
        title,
        text,
        icon,
        confirmButtonText,
        timer,
        ...rest,
    });
}

let loadingOverlay = null;
let loadingCount = 0;

function ensureLoadingOverlay() {
    if (loadingOverlay) {
        return loadingOverlay;
    }
    if (!document.getElementById('app-loading-style')) {
        const style = document.createElement('style');
        style.id = 'app-loading-style';
        style.textContent = `
            .app-loading-overlay {
                position: fixed;
                inset: 0;
                z-index: 9998;
                display: flex;
                align-items: center;
                justify-content: center;
                background: rgba(241, 245, 249, 0.58);
                backdrop-filter: blur(2px);
                opacity: 0;
                pointer-events: none;
                transition: opacity 120ms ease;
            }
            .app-loading-overlay.is-visible {
                opacity: 1;
                pointer-events: auto;
            }
            .app-loading-card {
                display: flex;
                align-items: center;
                gap: 12px;
                min-width: 220px;
                max-width: min(92vw, 360px);
                padding: 14px 18px;
                border: 1px solid rgba(148, 163, 184, 0.22);
                border-radius: 18px;
                background: rgba(255, 255, 255, 0.94);
                box-shadow: 0 18px 40px rgba(15, 23, 42, 0.12);
            }
            .app-loading-spinner {
                width: 22px;
                height: 22px;
                border-radius: 999px;
                border: 3px solid rgba(13, 178, 156, 0.18);
                border-top-color: #0db29c;
                animation: app-loading-spin 0.72s linear infinite;
                flex: 0 0 auto;
            }
            .app-loading-text {
                color: #0f172a;
                font-size: 14px;
                font-weight: 600;
                letter-spacing: 0.01em;
            }
            @keyframes app-loading-spin {
                to { transform: rotate(360deg); }
            }
        `;
        document.head.appendChild(style);
    }
    const overlay = document.createElement('div');
    overlay.className = 'app-loading-overlay';
    overlay.setAttribute('aria-hidden', 'true');
    overlay.innerHTML = `
        <div class="app-loading-card" role="status" aria-live="polite">
            <div class="app-loading-spinner" aria-hidden="true"></div>
            <div class="app-loading-text">Loading...</div>
        </div>
    `;
    document.body.appendChild(overlay);
    loadingOverlay = overlay;
    return overlay;
}

function showLoading(title = 'Loading...') {
    const overlay = ensureLoadingOverlay();
    const textNode = overlay.querySelector('.app-loading-text');
    if (textNode) {
        textNode.textContent = title || 'Loading...';
    }
    loadingCount += 1;
    overlay.classList.add('is-visible');
    overlay.setAttribute('aria-hidden', 'false');
    document.body.classList.add('app-loading-active');
    return overlay;
}

function closeLoading() {
    loadingCount = Math.max(loadingCount - 1, 0);
    if (loadingCount > 0) {
        return;
    }
    if (loadingOverlay) {
        loadingOverlay.classList.remove('is-visible');
        loadingOverlay.setAttribute('aria-hidden', 'true');
    }
    document.body.classList.remove('app-loading-active');
}

function confirmDialog(options = {}) {
    const defaultOptions = {
        title: 'Please confirm',
        text: '',
        icon: 'warning',
        confirmButtonText: 'Yes',
        cancelButtonText: 'Cancel',
        showCancelButton: true,
        focusCancel: true,
        reverseButtons: true,
        allowOutsideClick: false,
    };
    if (typeof Swal === 'undefined') {
        const confirmed = confirm(`${options.title || defaultOptions.title}\n${options.text || ''}`);
        return Promise.resolve({ isConfirmed: confirmed });
    }
    return Swal.fire({
        ...defaultOptions,
        ...options,
    });
}

async function logout(){
    const confirmation = await confirmDialog({
        title: 'Sign out?',
        text: 'You will need to log in again to continue.',
        confirmButtonText: 'Logout',
    });
    if (!confirmation.isConfirmed) {
        return;
    }
    try {
        await fetch('/api/auth/logout', { method: 'POST' });
    } catch {
        // ignore network errors during logout
    }
    clearAuthState();
    window.location.href = '/login';
}

async function fetchJSON(url, options={}){
    const headers = Object.assign({'Content-Type':'application/json'}, authHeaders(), options.headers || {});
    const method = String(options.method || 'GET').toUpperCase();
    const fetchOptions = { ...options, headers };
    if (method === 'GET' && fetchOptions.cache === undefined) {
        fetchOptions.cache = 'no-store';
    }
    if (fetchOptions.credentials === undefined) {
        fetchOptions.credentials = 'same-origin';
    }
    if (method === 'GET') {
        fetchOptions.headers = Object.assign({}, fetchOptions.headers, {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            Pragma: 'no-cache',
        });
    }
    const res = await fetch(url, fetchOptions);
    if(!res.ok){
        let message;
        try {
            message = await formatError(res);
        } catch {
            message = res.statusText || 'Request failed';
        }
        const error = new Error(message || 'Request failed');
        error.status = res.status;
        throw error;
    }
    return res.json();
}

async function formatError(response) {
    try {
        const payload = await response.json();
        if (payload?.detail) {
            if (Array.isArray(payload.detail)) {
                return payload.detail.map((entry) => entry.msg || JSON.stringify(entry)).join('; ');
            }
            return payload.detail;
        }
        if (payload?.message) {
            return payload.message;
        }
        if (typeof payload === 'string') {
            return payload;
        }
    } catch {
        // ignore
    }
    return response.statusText || 'Server error';
}
