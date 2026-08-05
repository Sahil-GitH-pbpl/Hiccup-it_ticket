(function () {
const detailContainer = document.getElementById('hiccup-detail');
const internalSection = document.getElementById('internal-detail-section');
const publicSummarySection = document.getElementById('public-summary-section');
const publicSummary = document.getElementById('public-summary');
const publicDescription = document.getElementById('public-description');
const publicImmediate = document.getElementById('public-immediate');
const publicStatus = document.getElementById('public-status');
const publicAttachments = document.getElementById('public-attachments');
const auditCard = document.getElementById('audit-log');
const auditList = document.querySelector('#audit-log .mt-4');
const followupCard = document.getElementById('followup-card');
const followupStatusText = document.getElementById('followup-status');
const followupForm = document.getElementById('hiccup-followup-form');
const followupSelect = document.getElementById('followup-state');
const followupComment = document.getElementById('followup-comment');
const responseStatus = document.getElementById('response-status');
const responseForm = document.getElementById('response-form-body');
const responseTextarea = document.getElementById('response-text');
const responseSection = document.getElementById('response-form');
const tokenField = document.getElementById('public-token-field');
const publicTokenFromUrl = new URL(window.location.href).searchParams.get('public_token') || '';
const publicToken = window.PUBLIC_TOKEN || tokenField?.value || publicTokenFromUrl;
const isPublicResponse = Boolean(publicToken);
const hiccupId = window.currentHiccupId;
const responseNote = document.getElementById('response-note');
const responseAttachment = document.getElementById('response-attachment');
const responseAttachmentsList = document.getElementById('response-attachments-list');
const responseContext = document.getElementById('response-context');
const initialHiccupData = window.initialHiccupData ?? null;
const detailCurrentUser = window.currentUser || {};
const detailCurrentUserRole = window.currentUserRole || detailCurrentUser.role || null;
const detailCurrentUserId = detailCurrentUser.user_id || null;
let detailDepartmentCache = null;

async function ensureDepartmentCache() {
    if (detailDepartmentCache) {
        return detailDepartmentCache;
    }
    try {
        const res = await fetch('/api/staff/departments', {
            headers: authHeaders(),
        });
        if (!res.ok) {
            throw new Error('Unable to load departments');
        }
        const list = await res.json();
        detailDepartmentCache = new Map();
        list.forEach((dept) => {
            if (dept?.id && dept?.name) {
                detailDepartmentCache.set(String(dept.id), dept.name);
            }
        });
        return detailDepartmentCache;
    } catch (err) {
        console.error('Failed to fetch departments', err);
        return new Map();
    }
}

async function resolveAgainstDepartmentName(hiccup) {
    if (hiccup.raised_against_department_name) {
        return hiccup.raised_against_department_name;
    }
    const deptId = hiccup.raised_against_department;
    if (!deptId) {
        return null;
    }
    const cache = await ensureDepartmentCache();
    return cache.get(String(deptId)) || null;
}

const escapeHtml =
    window.escapeHtml ||
    function (value) {
        if (value === null || value === undefined) {
            return '';
        }
        return String(value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    };

function buildDetailHTML(hiccup) {
    const rows = [
        ['ID', hiccup.hiccup_id],
        ['Type', hiccup.hiccup_type],
        ['Status', hiccup.status],
        ['Created By', hiccup.raised_by_name || '-'],
        ['Department', hiccup.raised_by_department || '-'],
        ['Created', hiccup.created_at ? new Date(hiccup.created_at).toLocaleString() : '-'],
    ];
    return `
        <div class="grid gap-3 sm:grid-cols-2">
            ${rows
                .map(
                    ([label, value]) => `
                        <div class="flex flex-col gap-1 rounded-2xl border border-slate-100 bg-slate-50/80 p-3">
                            <p class="text-[10px] uppercase tracking-[0.4em] text-slate-500">${label}</p>
                            <p class="text-sm font-semibold text-slate-900">${value ?? '-'}</p>
                        </div>
                    `
                )
                .join("")}
        </div>
        <div class="mt-4 grid gap-4 rounded-2xl border border-slate-100 bg-white/80 p-4 text-sm">
            <div>
                <p class="text-[10px] uppercase tracking-[0.4em] text-slate-500">Description</p>
                <p class="text-slate-900 mt-1">${hiccup.description || '-'}</p>
            </div>
            <div>
                <p class="text-[10px] uppercase tracking-[0.4em] text-slate-500">Immediate Effect</p>
                <p class="text-slate-900 mt-1">${hiccup.immediate_effect || '-'}</p>
            </div>
            ${
                hiccup.status === 'Closed' && hiccup.closure_notes
                    ? `
                        <div class="rounded-2xl border border-emerald-100 bg-emerald-50/70 p-3 text-sm text-emerald-900">
                            <p class="text-[10px] uppercase tracking-[0.4em] text-emerald-700">Closure Notes</p>
                            <p class="mt-2">${hiccup.closure_notes}</p>
                        </div>
                    `
                    : ''
            }
        </div>
    `;
}

function renderPublicSummary(hiccup) {
    if (!publicSummary) return;
    const summaryPieces = [
        ['Hiccup ID', hiccup.hiccup_id],
        ['Status', hiccup.status],
        ['Type', hiccup.hiccup_type],
        ['Raised By', hiccup.raised_by_name || '-'],
        ['Department', hiccup.raised_against_department_name || hiccup.raised_against_department || '-'],
        ['Created', hiccup.created_at ? new Date(hiccup.created_at).toLocaleString() : '-'],
    ];
    publicSummary.innerHTML = summaryPieces
        .map(
            ([label, value]) => `
                <div class="rounded-2xl border border-slate-200 bg-slate-50/70 p-3 text-[16px] text-slate-900">
                    <p class="text-[10px] uppercase tracking-[0.25em] text-slate-500">${label}</p>
                    <p class="mt-1 font-semibold">${value ?? '-'}</p>
                </div>
            `
        )
        .join('');
    (publicDescription || {}).textContent = hiccup.description || 'No description provided.';
    (publicImmediate || {}).textContent = hiccup.immediate_effect || 'No effect noted.';
    if (publicAttachments) {
        const attachmentSource =
            Array.isArray(hiccup.attachments) && hiccup.attachments.length
                ? hiccup.attachments
                : hiccup.attachment_path;
        publicAttachments.innerHTML = formatAttachment(attachmentSource);
    }
    if (publicStatus) {
        publicStatus.textContent = hiccup.status || '—';
    }
    publicSummarySection?.classList.remove('hidden');
    internalSection?.classList.add('hidden');
}

function renderAudit(logs = []) {
    if (!auditList) return;
    if (!logs.length) {
        auditList.innerHTML = '<p class="text-sm text-slate-500">No audit history yet.</p>';
        return;
    }
    auditList.innerHTML = logs
        .map(
            (entry) => `
                <div class="mb-3 rounded-2xl border border-slate-100 bg-slate-50/80 p-3">
                    <p class="text-xs uppercase tracking-[0.3em] text-slate-500">${entry.action}</p>
                    <p class="text-sm text-slate-900 mt-1">${new Date(entry.timestamp).toLocaleString()}</p>
                    <p class="text-sm text-slate-600 mt-1">By ${entry.performed_by_name || entry.performed_by}${entry.remarks ? ` — ${entry.remarks}` : ''}</p>
                </div>
            `
        )
        .join('');
}

function renderFollowupSection(hiccup) {
    if (!followupCard) return;
    if (isPublicResponse) {
        followupCard.classList.add('hidden');
        return;
    }
    followupCard.classList.remove('hidden');
    const currentStatus = hiccup.followup_status || 'Pending';
    const comment = hiccup.followup_comment || 'No updates yet';
    followupStatusText.textContent = `Status: ${currentStatus}. Comment: ${comment}`;
    const userId = detailCurrentUserId;
    const canSubmit =
        userId && Number(userId) === hiccup.raised_by && ['Closed', 'Escalated to NC'].includes(hiccup.status);
    const closedAt = hiccup.closed_at ? new Date(hiccup.closed_at).getTime() : null;
    const dueWindow =
        closedAt && Date.now() - closedAt >= 7 * 24 * 60 * 60 * 1000;
    if (canSubmit && dueWindow) {
        followupForm?.classList.remove('hidden');
    } else {
        followupForm?.classList.add('hidden');
    }
}

function canRespondToHiccup(hiccup) {
    if (isPublicResponse) {
        return true;
    }
    const userId = detailCurrentUserId;
    if (!userId) {
        return false;
    }
    const isMgmt = ['management', 'admin'].includes((detailCurrentUserRole || '').toLowerCase());
    if (hiccup.raised_against && String(hiccup.raised_against) === String(userId)) {
        return true;
    }
    return isMgmt;
}

function renderResponseSection(hiccup) {
    if (!responseSection || !responseStatus) {
        return;
    }
    const canRespond = canRespondToHiccup(hiccup);
    const overdue = Boolean(hiccup.is_response_overdue);
    const locked = Boolean(hiccup.response_blocked);
    const hasResponse = Boolean(hiccup.response_text);
    const responderName = hiccup.response_by_name || hiccup.response_by || 'unknown';
    if (isPublicResponse) {
        responseStatus.textContent = hasResponse
            ? `Responded by ${responderName}: ${hiccup.response_text}`
            : 'Use the form below to explain the hiccup and send a response.';
    } else {
        responseStatus.textContent = hasResponse
            ? `Responded by ${responderName}: ${hiccup.response_text}`
            : 'Awaiting response from assigned staff or management';
    }
    renderResponseContext(hiccup);
    if (!responseForm) {
        return;
    }
    if (locked) {
        responseNote && (responseNote.textContent = 'Response window closed after 72 hours; management will escalate to NC.');
        responseTextarea?.setAttribute('disabled', 'disabled');
        responseForm?.classList.add('opacity-70');
        responseForm?.querySelector('[type="submit"]')?.setAttribute('disabled', 'disabled');
        return;
    }
    if (!canRespond) {
        responseForm.classList.add('hidden');
        responseTextarea?.setAttribute('disabled', 'disabled');
        return;
    }
    responseForm.classList.remove('opacity-70');
    responseForm?.querySelector('[type="submit"]')?.removeAttribute('disabled');
    responseNote && (responseNote.textContent = overdue
        ? 'Important: this hiccup has been overdue for 24 hours; respond ASAP or management may escalate.'
        : 'Important: respond within 24 hours to avoid overdue flag; after 72 hours management will escalate to NC.');
    responseForm.classList.remove('hidden');
    responseTextarea?.removeAttribute('disabled');
    responseTextarea.value = hiccup.response_text || '';
}

function buildAttachmentAnchors(paths = []) {
    return paths.map((path) => {
        const normalizedHref = path.startsWith('/') ? path : `/${path}`;
        const filename = path.split('/').pop() || 'attachment';
        return `<a class="underline text-tealbrand" href="${encodeURI(normalizedHref)}" target="_blank" rel="noreferrer">${escapeHtml(filename)}</a>`;
    });
}

function renderResponseContext(hiccup) {
    if (responseContext) {
        responseContext.classList.add('hidden');
    }
}

function renderResponseAttachment(hiccup) {
    if (!responseAttachment || !responseAttachmentsList) {
        return;
    }
    const attachmentSource =
        hiccup && Array.isArray(hiccup.attachments) && hiccup.attachments.length
            ? hiccup.attachments
            : hiccup && hiccup.attachment_path;
    const attachments = normalizeAttachments(attachmentSource || []);
    if (!attachments.length) {
        responseAttachment.classList.add('hidden');
        responseAttachmentsList.innerHTML = '';
        return;
    }
    responseAttachmentsList.innerHTML = formatAttachment(attachments);
    responseAttachment.classList.remove('hidden');
}

async function submitHiccupResponse(event) {
    event.preventDefault();
    if (!responseTextarea) return;
    const value = responseTextarea.value.trim();
    if (!value) {
        await showAlert({ icon: 'warning', title: 'Response required', text: 'Add some context before submitting.' });
        responseTextarea.focus();
        return;
    }
    if (!hiccupId) {
        return;
    }
    let endpoint = `/api/hiccups/${hiccupId}/respond`;
    if (isPublicResponse) {
        const url = new URL(`/api/hiccups/public/${hiccupId}/respond`, window.location.origin);
        url.searchParams.set('public_token', publicToken);
        endpoint = url.toString();
    }
    if (isPublicResponse) {
        console.debug('Submitting public response', publicToken, endpoint);
    }
    try {
        responseSection?.classList.add('opacity-70');
        const res = await fetch(endpoint, {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json',
                ...authHeaders(),
            },
            body: JSON.stringify({
                response_text: value,
                ...(isPublicResponse ? { public_token: publicToken } : {}),
            }),
        });
        if (!res.ok) {
            const message = await formatError(res);
            throw new Error(message || 'Unable to submit response');
        }
        await showAlert({ icon: 'success', title: 'Response saved', timer: 1200, showConfirmButton: false });
        if (isPublicResponse) {
            responseTextarea?.setAttribute('disabled', 'disabled');
            responseTextarea.value = '';
            responseForm?.querySelector('[type="submit"]')?.setAttribute('disabled', 'disabled');
            responseStatus.textContent = 'Response recorded; this link is now disabled.';
            return;
        }
        loadHiccupDetail();
    } catch (err) {
        console.error('Response submit failed', err);
        await showAlert({ icon: 'error', title: 'Failed to respond', text: err?.message || 'Please try again.' });
    } finally {
        responseSection?.classList.remove('opacity-70');
    }
}

async function submitFollowup(event) {
    if (!hiccupId || !followupForm) return;
    event && event.preventDefault();
    const status = followupSelect.value;
    if (!status) {
        await showAlert({ icon: 'warning', title: 'Follow-up status required', text: 'Choose whether it was resolved or not.' });
        return;
    }
    const payload = {
        followup_status: status,
        followup_comment: followupComment.value.trim(),
    };
    try {
        await fetch(`/api/hiccups/${hiccupId}/followup`, {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json',
                ...authHeaders(),
            },
            body: JSON.stringify(payload),
        });
        await showAlert({ icon: 'success', title: 'Follow-up saved', timer: 1200, showConfirmButton: false });
        loadHiccupDetail();
    } catch (err) {
        await showAlert({ icon: 'error', title: 'Unable to save follow-up', text: err?.message || 'Try again later.' });
        console.error(err);
    }
}

async function applyHiccupData(hiccup) {
    const resolvedDeptName = await resolveAgainstDepartmentName(hiccup);
    if (resolvedDeptName && !hiccup.raised_against_department_name) {
        hiccup.raised_against_department_name = resolvedDeptName;
    }
    if (isPublicResponse) {
        renderPublicSummary(hiccup);
        auditCard?.classList.add('hidden');
    } else {
        publicSummarySection?.classList.add('hidden');
        internalSection?.classList.remove('hidden');
        if (detailContainer) {
            detailContainer.innerHTML = buildDetailHTML(hiccup);
        }
        auditCard?.classList.remove('hidden');
        const logs = await fetchJSON(`/api/hiccups/${hiccupId}/audit_log`);
        renderAudit(logs);
    }
    renderFollowupSection(hiccup);
    renderResponseSection(hiccup);
    renderResponseAttachment(hiccup);
}

async function loadHiccupDetail() {
    if (!hiccupId) return;
    if (initialHiccupData) {
        await applyHiccupData(initialHiccupData);
        if (isPublicResponse) {
            return;
        }
    }
    try {
        const hiccup = await fetchJSON(`/api/hiccups/${hiccupId}`);
        await applyHiccupData(hiccup);
    } catch (err) {
        console.error('Unable to load hiccup detail', err);
        if (!initialHiccupData) {
            detailContainer && (detailContainer.innerHTML = '<p class="text-sm text-red-500">Unable to load hiccup.</p>');
            await showAlert?.({
                icon: 'error',
                title: 'Unable to load hiccup',
                text: err?.message || 'Please try again later.',
            });
        }
    }
}

function attachFormListeners() {
    followupForm?.addEventListener('submit', submitFollowup);
    responseForm?.addEventListener('submit', submitHiccupResponse);
}

document.addEventListener('DOMContentLoaded', () => {
    attachFormListeners();
    loadHiccupDetail();
    const responseTextarea = document.getElementById('response-text');
    const counter = document.getElementById('response-char-count');
    if (responseTextarea && counter) {
        const update = () => {
            const len = responseTextarea.value.length;
            counter.textContent = `${len} / 600`;
        };
        responseTextarea.addEventListener('input', update);
        update();
    }
});
window.submitHiccupResponse = submitHiccupResponse;
})();
