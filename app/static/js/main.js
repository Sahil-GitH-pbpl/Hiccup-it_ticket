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
        didOpen: (popup) => {
            bindModalKeyboardShortcuts(popup);
            if (typeof rest.didOpen === 'function') {
                rest.didOpen(popup);
            }
        },
    });
}

function showLoading(title = 'Loading...') {
    return null;
}

function closeLoading() {
    return null;
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
        didOpen: (popup) => {
            bindModalKeyboardShortcuts(popup);
            if (typeof options.didOpen === 'function') {
                options.didOpen(popup);
            }
        },
    });
}

function bindModalKeyboardShortcuts(root) {
    if (!root || root.dataset.modalShortcutBound === 'true') {
        return;
    }
    root.dataset.modalShortcutBound = 'true';
    root.addEventListener('keydown', (event) => {
        if (event.ctrlKey && event.key === 'Enter') {
            event.preventDefault();
            const confirmButton =
                root.querySelector('.swal2-confirm') ||
                root.querySelector('[data-modal-confirm]') ||
                root.querySelector('button[type="submit"]');
            if (confirmButton && !confirmButton.disabled) {
                confirmButton.click();
            }
            return;
        }
        if (event.key === 'Escape') {
            const cancelButton =
                root.querySelector('.swal2-cancel') ||
                root.querySelector('[data-modal-close]') ||
                root.querySelector('.swal2-close');
            if (cancelButton && !cancelButton.disabled) {
                event.preventDefault();
                cancelButton.click();
            }
        }
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
