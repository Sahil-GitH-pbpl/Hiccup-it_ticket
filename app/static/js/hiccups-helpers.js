// Shared helpers for hiccup tables and modals. Keep lightweight for reuse across pages.
function escapeHtml(value) {
    if (value === null || value === undefined) {
        return '-';
    }
    return String(value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function normalizeText(value) {
    const escaped = escapeHtml(value);
    if (escaped.trim() === '') {
        return '-';
    }
    return escaped;
}

function formatDate(value) {
    if (!value) return '-';
    try {
        return new Date(value).toLocaleString();
    } catch {
        return escapeHtml(value);
    }
}

function formatPersonDisplay(name, id) {
    const safeName = name?.trim() ? escapeHtml(name) : null;
    const safeId = id !== undefined && id !== null ? escapeHtml(String(id)) : null;
    if (safeName && safeId) {
        return `${safeName}`;
    }
    if (safeName) {
        return safeName;
    }
    if (safeId) {
        return safeId;
    }
    return '-';
}

function formatAttachment(path) {
    const attachments = normalizeAttachments(path);
    if (!attachments.length) return '<span class="text-slate-400">No attachments</span>';
    const links = attachments
        .map((entry, idx) => {
            const filename = escapeHtml(entry.split('/').pop() || 'attachment');
            const normalized = entry.startsWith('/') ? entry : `/${entry}`;
            const href = encodeURI(normalized);
            const isImage = /\.(png|jpe?g|gif|bmp|webp|svg)$/i.test(entry.split('?')[0] || '');
            const label = isImage ? `Image ${idx + 1}` : filename;
            return `<a href="${href}" target="_blank" rel="noreferrer" class="text-tealbrand underline">${label}</a>`;
        })
        .join('');
    return `<div class="attachment-row">${links}</div>`;
}

function truncatedText(value, max = 120) {
    if (value === null || value === undefined) {
        return '-';
    }
    const text = String(value).trim();
    if (!text) {
        return '-';
    }
    const escaped = escapeHtml(text);
    if (escaped.length <= max) {
        return escaped;
    }
    return `${escaped.slice(0, max)}&hellip;`;
}

function formatOverdueBadges(hiccup) {
    const badges = [];
    if (hiccup.is_response_overdue || hiccup.was_response_overdue) {
        badges.push('<span class="rounded-full bg-rose-100 px-3 py-0.5 text-[10px] font-semibold uppercase tracking-[0.3em] text-rose-600">Response overdue</span>');
    }
    if (hiccup.is_closure_overdue) {
        badges.push('<span class="rounded-full bg-amber-100 px-3 py-0.5 text-[10px] font-semibold uppercase tracking-[0.3em] text-amber-600">Closure overdue</span>');
    }
    return badges.join(' ');
}

function statusWithBadges(h) {
    const badges = formatOverdueBadges(h);
    return `<div class="space-y-1 text-sm">
        <span class="font-semibold text-slate-900">${normalizeText(h.status)}</span>
        ${badges ? `<div class="flex flex-wrap gap-2">${badges}</div>` : ''}
    </div>`;
}

function matchesGlobalSearch(entry, query) {
    if (!query) {
        return true;
    }
    const normalized = query.trim().toLowerCase();
    if (!normalized) {
        return true;
    }
    const fields = [
        entry.hiccup_id,
        entry.hiccup_type,
        entry.status,
        entry.description,
        entry.immediate_effect,
        entry.response_text,
        entry.raised_by_name,
        entry.raised_against_name,
        entry.raised_against_department_name,
        entry.raised_against_department,
        entry.raised_by_department,
        entry.root_cause_category,
    ].filter(Boolean);
    const haystack = fields
        .map((value) => String(value).toLowerCase())
        .join(' ');
    return haystack.includes(normalized);
}

function normalizeAttachments(value) {
    if (!value) return [];
    if (Array.isArray(value)) {
        return value.map((item) => String(item).trim()).filter(Boolean);
    }
    if (typeof value === 'string') {
        const trimmed = value.trim();
        if (!trimmed) return [];
        try {
            const parsed = JSON.parse(trimmed);
            if (Array.isArray(parsed)) {
                return parsed.map((item) => String(item).trim()).filter(Boolean);
            }
        } catch (err) {
            // ignore parsing failures; treat as raw path
        }
        return [trimmed];
    }
    return [];
}
