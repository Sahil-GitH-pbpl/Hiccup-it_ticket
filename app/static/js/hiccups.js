let myHiccupsData = [];
const statusFilter = document.getElementById('filter-status');
const typeFilter = document.getElementById('filter-type');
const resetFilters = document.getElementById('reset-filters');
const globalSearchInput = document.getElementById('global-hiccup-search');
const mgmtStatusFilter = document.getElementById('mgmt-filter-status');
const mgmtTypeFilter = document.getElementById('mgmt-filter-type');
const mgmtRootFilter = document.getElementById('mgmt-filter-root');
const mgmtGlobalSearchInput = document.getElementById('mgmt-global-hiccup-search');
const mgmtResetFilters = document.getElementById('mgmt-reset-filters');

const summaryColumnCount = 6;
const actionsColumnCount = 1;
const listColumnCount = summaryColumnCount + actionsColumnCount;
const showManagementActions = Boolean(window.managementActionsEnabled);
const managementColumnCount = summaryColumnCount + (showManagementActions ? actionsColumnCount : 0);
const assignedViewMode = Boolean(window.assignedView);
const currentUserId = window.currentUserId || (window.currentUser && window.currentUser.user_id) || null;
const currentUserName = (window.currentUser && window.currentUser.name) || '';
let departmentCache = null;
const hasHiccupTables =
    Boolean(document.querySelector('#my-hiccups-table')) ||
    Boolean(document.querySelector('#management-table')) ||
    Boolean(document.querySelector('#assigned-table'));

async function ensureDepartmentCache() {
    if (departmentCache) {
        return departmentCache;
    }
    const map = new Map();
    try {
        const res = await fetch('/api/staff/departments', {
            headers: authHeaders(),
        });
        if (!res.ok) {
            throw new Error('Unable to load departments');
        }
        const list = await res.json();
        list.forEach((dept) => {
            if (dept?.id && dept?.name) {
                map.set(String(dept.id), dept.name);
            }
        });
    } catch (err) {
        console.error('Failed to load departments', err);
    }
    departmentCache = map;
    return departmentCache;
}

async function hydrateRaisedAgainstNames(rows) {
    if (!Array.isArray(rows) || rows.length === 0) {
        return;
    }
    const cache = await ensureDepartmentCache();
    if (!cache || !cache.size) {
        return;
    }
    rows.forEach((row) => {
        if (!row.raised_against_department_name && row.raised_against_department) {
            const name = cache.get(String(row.raised_against_department));
            if (name) {
                row.raised_against_department_name = name;
            }
        }
    });
}

const SUGGESTION_DEBOUNCE = 300;

function managementActionButtons(hiccup) {
    const { hiccup_id: id, status, escalated_by } = hiccup;
    const hasEscalation = Boolean(escalated_by);
    // If closed without any NC escalation history, no management actions are needed.
    if (status === 'Closed' && !hasEscalation) {
        return '';
    }
    const actions = [];
    if (status !== 'Closed') {
        actions.push({
            status: 'Closed',
            label: 'Close',
            classes: 'text-rose-600 border-rose-300',
            behavior: 'status-change',
        });
    }
    const escalationAction =
        status === 'Escalated to NC' || (status === 'Closed' && hasEscalation)
            ? {
                  label: 'View NC',
                  classes: 'text-amber-600 border-amber-300',
                  behavior: 'view-nc',
              }
            : {
                  status: 'Escalated to NC',
                  label: 'Escalate NC',
                  classes: 'text-amber-600 border-amber-300',
                  behavior: 'status-change',
              };
    actions.push(escalationAction);
    return actions
        .map((action) => {
            const statusAttr = action.status ? `data-status="${action.status}"` : '';
            const behaviorAttr = action.behavior ? `data-behavior="${action.behavior}"` : '';
            return `<button type="button" class="mgmt-pill ${action.classes}" data-hiccup="${id}" ${statusAttr} ${behaviorAttr}>${action.label}</button>`;
        })
        .join('');
}

function actionCellHtml(h, includeMgmtActions = false, options = {}) {
    const { allowNcView = false, ncReadonly = false, allowRespond = false } = options;
    const detailButton = `<button type="button" data-hiccup-detail="${h.hiccup_id}" class="detail-btn" aria-label="tails for ${escapeHtml(h.hiccup_id)}">View details</button>`;
    let mgmtActions = '';
    if (includeMgmtActions) {
        const mgmtButtons = managementActionButtons(h);
        if (mgmtButtons) {
            mgmtActions = `<div class="mgmt-action-group" data-hiccup-actions="${h.hiccup_id}">
                <button type="button" class="mgmt-toggle" aria-haspopup="true" aria-expanded="false">Actions</button>
                <div class="mgmt-actions-stack">
                    ${mgmtButtons}
                </div>
           </div>`;
        }
    }
    const ncViewButton =
        allowNcView && (h.status === 'Escalated to NC' || h.escalated_by)
            ? `<button type="button" class="detail-btn" data-behavior="view-nc" data-nc-readonly="${ncReadonly}" data-hiccup="${h.hiccup_id}">View NC Form</button>`
            : '';
    const respondButton =
        allowRespond && h.status !== 'Closed'
            ? `<button type="button" class="detail-btn" data-behavior="respond" data-hiccup="${h.hiccup_id}">Respond</button>`
            : '';
    return `<td class="px-4 py-3 align-top">
        <div class="flex flex-col gap-3">
            ${detailButton}
            ${mgmtActions}
            ${ncViewButton}
            ${respondButton}
        </div>
    </td>`;
}

function detailMarkup(h, ncForm) {
    const summaryCards = [
        { title: 'Created By', value: formatPersonDisplay(h.raised_by_name) },
        { title: 'Created Against', value: formatPersonDisplay(h.raised_against_name) },
        { title: 'Type', value: normalizeText(h.hiccup_type) },
        { title: 'Status', value: normalizeText(h.status) },
    ];
    const detailCards = [
        { title: 'Response By', value: formatPersonDisplay(h.response_by_name, h.response_by) },
        { title: 'Raised Dept', value: normalizeText(h.raised_by_department) },
        { title: 'Against Dept', value: normalizeText(h.raised_against_department_name || h.raised_against_department) },
        { title: 'Root Cause', value: normalizeText(h.root_cause_category) },
    ];
    if (ncForm?.staff_name) {
        detailCards.push({
            title: 'NC Escalated Staff',
            value: formatPersonDisplay(ncForm.staff_name),
        });
    }
    if (h.nc_assigned_staff_name) {
        detailCards.push({
            title: 'Assigned Staff',
            value: formatPersonDisplay(h.nc_assigned_staff_name),
        });
    }
    const attachmentSource =
        Array.isArray(h.attachments) && h.attachments.length ? h.attachments : h.attachment_path;
    const renderCards = (cards) =>
        cards
            .map(
                ({ title, value }) => `
                    <div class="rounded-2xl border border-slate-100 bg-white/90 p-2 text-sm text-slate-900">
                        <p class="text-[10px] uppercase tracking-[0.3em] text-slate-500">${title}</p>
                        <p class="mt-2 text-lg font-semibold text-slate-900">${value ?? '-'}</p>
                    </div>
                `
            )
            .join('');
    const narrative = `
        <div class="grid gap-2 sm:grid-cols-2">
            <div class="rounded-2xl border border-slate-100 bg-slate-50/70 p-3">
                <p class="text-xs uppercase tracking-[0.4em] text-slate-500">Description</p>
                <p class="mt-2 text-sm text-slate-900">${truncatedText(h.description, 200)}</p>
            </div>
            <div class="rounded-2xl border border-slate-100 bg-slate-50/70 p-3">
                <p class="text-xs uppercase tracking-[0.4em] text-slate-500">Immediate Effect</p>
                <p class="mt-2 text-sm text-slate-900">${truncatedText(h.immediate_effect, 200)}</p>
            </div>
            ${
                h.status === 'Closed' && h.closure_notes
                    ? `<div class="rounded-2xl border border-slate-100 bg-emerald-50/70 p-3 sm:col-span-2">
                        <p class="text-xs uppercase tracking-[0.4em] text-emerald-700">Closure Notes</p>
                        <p class="mt-2 text-sm text-emerald-900">${truncatedText(h.closure_notes, 260)}</p>
                       </div>`
                    : ''
            }
        </div>
    `;
    const responseHtml = h.response_text
        ? `
            <div class="rounded-3xl border border-teal-200 bg-teal-50/70 p-3 shadow-sm mx-auto w-full">
                <p class="text-[10px] uppercase tracking-[0.4em] text-tealbrand">Response</p>
                <p class="mt-2 text-lg font-semibold text-slate-900 leading-relaxed">${escapeHtml(h.response_text)}</p>
                <p class="text-xs mt-2 text-slate-500">Responded by <span class="font-semibold text-slate-900">${formatPersonDisplay(h.response_by_name, h.response_by)}</span></p>
            </div>`
        : '';
    const badges = `
        <div class="flex flex-wrap gap-2 text-[10px] uppercase tracking-[0.3em] text-slate-500">
            ${formatOverdueBadges(h)}
            <span class="rounded-full border border-slate-200 px-3 py-1">Auto: ${h.is_auto_generated ? 'Yes' : 'No'}</span>
            <span class="rounded-full border border-slate-200 px-3 py-1">Confidential: ${h.confidential_flag ? 'Yes' : 'No'}</span>
        </div>
    `;
    return `
        <div class="space-y-3 text-slate-700 text-sm max-w-[620px]">
            <div class="grid gap-2 sm:grid-cols-2 md:grid-cols-3">
                ${renderCards(summaryCards)}
            </div>
            <div class="grid gap-2 sm:grid-cols-2 md:grid-cols-4">
                ${renderCards(detailCards)}
            </div>
            ${narrative}
            ${responseHtml}
            ${badges}
            <div class="grid gap-3 md:grid-cols-2">
                <div class="rounded-2xl border border-slate-100 bg-white/80 p-3">
                    <p class="text-[10px] uppercase tracking-[0.3em] text-slate-500">Attachments</p>
                    <div class="mt-2 text-sm text-slate-900 attachment-stack">
                        ${formatAttachment(attachmentSource)}
                    </div>
                </div>
                <div class="rounded-2xl border border-slate-100 bg-white/80 p-3">
                    <p class="text-[10px] uppercase tracking-[0.3em] text-slate-500">Follow-up</p>
                    <p class="mt-2 text-sm text-slate-900">${normalizeText(h.followup_status)} ${normalizeText(h.followup_comment)}</p>
                </div>
            </div>
        </div>
    `;
}
async function fetchNCEscalationForm(hiccupId) {
    try {
        return await fetchJSON(`/api/hiccups/${hiccupId}/nc-form`);
    } catch (err) {
        console.error('Unable to load NC escalation form', err);
        return null;
    }
}

async function presentHiccupDetails(h) {
    let ncForm = null;
    if (h.status === 'Escalated to NC') {
        ncForm = await fetchNCEscalationForm(h.hiccup_id);
    }
    Swal.fire({
        title: `Hiccup ${escapeHtml(h.hiccup_id)}`,
        html: detailMarkup(h, ncForm),
        width: 640,
        showCloseButton: true,
        confirmButtonText: 'Close',
        background: '#fff',
        customClass: {
            popup: 'swal-detail-popup',
        },
    });
}

function summaryRowHtml(h, includeActions = true, includeMgmtActions = false, options = {}) {
    const { displayRaisedAgainst = true, allowNcView = false, ncReadonly = false, allowRespond = false } = options;
    const actionCell = includeActions ? actionCellHtml(h, includeMgmtActions, { allowNcView, ncReadonly, allowRespond }) : '';
    const targetPerson = displayRaisedAgainst
        ? formatPersonDisplay(h.raised_against_name, h.raised_against)
        : formatPersonDisplay(h.raised_by_name, h.raised_by);
    return `<tr class="border-b border-slate-100 hover:bg-white">
        <td class="px-4 py-3 align-top">
            <button type="button" data-hiccup-detail="${h.hiccup_id}" class="font-semibold text-tealbrand detail-btn">
                ${escapeHtml(h.hiccup_id)}
            </button>
        </td>
        <td class="px-4 py-3 align-top">${normalizeText(h.hiccup_type)}</td>
        <td class="px-4 py-3 align-top">${statusWithBadges(h)}</td>
        <td class="px-4 py-3 align-top">${targetPerson}</td>
        <td class="px-4 py-3 align-top">${formatDate(h.created_at)}</td>
        <td class="px-4 py-3 align-top">${formatDate(h.updated_at)}</td>
        ${actionCell}
    </tr>`;
}

function matchesCurrentUser(value, fallbackName) {
    const userIdStr = currentUserId ? String(currentUserId).trim() : '';
    const valueStr = value !== undefined && value !== null ? String(value).trim() : '';
    if (userIdStr && valueStr && userIdStr === valueStr) {
        return true;
    }
    const userNameNorm = currentUserName ? currentUserName.trim().toLowerCase() : '';
    const nameNorm = fallbackName ? String(fallbackName).trim().toLowerCase() : '';
    return Boolean(userNameNorm && nameNorm && userNameNorm === nameNorm);
}

function resolveOptionValue(option, hiccup) {
    if (typeof option === 'function') {
        try {
            return Boolean(option(hiccup));
        } catch (err) {
            return false;
        }
    }
    return Boolean(option);
}

function hiccupCardHtml(h, options = {}) {
    const {
        displayRaisedAgainst = true,
        includeMgmtActions = false,
        allowNcView = false,
        ncReadonly = false,
        allowRespond = false,
    } = options;
    const targetPerson = displayRaisedAgainst
        ? formatPersonDisplay(h.raised_against_name, h.raised_against)
        : formatPersonDisplay(h.raised_by_name, h.raised_by);
    const attachments = Array.isArray(h.attachments)
        ? h.attachments
        : h.attachment_path
        ? [h.attachment_path]
        : [];
    const attachmentLabel = attachments.length
        ? `${attachments.length} attachment${attachments.length > 1 ? 's' : ''}`
        : 'No attachments';
    const allowNcViewForCard = resolveOptionValue(allowNcView, h);
    const allowRespondForCard = resolveOptionValue(allowRespond, h);
    const ncViewButton =
        allowNcViewForCard && (h.status === 'Escalated to NC' || h.escalated_by)
            ? `<button type="button" class="detail-btn" data-behavior="view-nc" data-nc-readonly="${ncReadonly}" data-hiccup="${h.hiccup_id}">View NC Form</button>`
            : '';
    const respondButton =
        allowRespondForCard && h.status !== 'Closed'
            ? `<button type="button" class="detail-btn" data-behavior="respond" data-hiccup="${h.hiccup_id}">Respond</button>`
            : '';
    const detailButton = `<button type="button" data-hiccup-detail="${h.hiccup_id}" class="detail-btn">View details</button>`;
    const mgmtButtons = includeMgmtActions ? managementActionButtons(h) : '';
    const mgmtSection = mgmtButtons
        ? `<div class="mgmt-action-group mt-2" data-hiccup-actions="${h.hiccup_id}">
                <button type="button" class="mgmt-toggle" aria-haspopup="true" aria-expanded="false">Actions</button>
                <div class="mgmt-actions-stack">
                    ${mgmtButtons}
                </div>
           </div>`
        : '';
    return `
        <article class="rounded-2xl border border-slate-200 bg-white shadow-sm p-4 space-y-2">
            <div class="flex items-start justify-between gap-3">
                <div>
                    <p class="text-[10px] uppercase tracking-[0.3em] text-slate-500">Hiccup</p>
                    <p class="text-lg font-semibold text-slate-900">#${escapeHtml(h.hiccup_id)}</p>
                </div>
                <div class="text-right text-xs">${statusWithBadges(h)}</div>
            </div>
            <p class="text-sm font-semibold text-slate-800">${normalizeText(h.hiccup_type)}</p>
            <p class="text-sm text-slate-600">${displayRaisedAgainst ? 'Against' : 'By'} ${targetPerson}</p>
            <p class="text-xs text-slate-500">Created ${formatDate(h.created_at)} | Updated ${formatDate(h.updated_at)}</p>
            <p class="text-sm text-slate-700">${truncatedText(h.description, 120)}</p>
            <div class="flex flex-wrap gap-2 text-xs text-slate-500">
                ${formatOverdueBadges(h)}
                <span class="rounded-full bg-slate-100 px-2 py-1">${attachmentLabel}</span>
            </div>
            <div class="flex flex-wrap gap-2 pt-2">
                ${detailButton}
                ${respondButton}
                ${ncViewButton}
            </div>
            ${mgmtSection}
        </article>
    `;
}

function renderHiccupCards(containerId, data, options = {}) {
    const container = document.getElementById(containerId);
    if (!container) return;
    const rows = Array.isArray(data) ? data : [];
    if (!rows.length) {
        container.innerHTML = `<div class="rounded-xl border border-dashed border-slate-200 bg-slate-50 px-4 py-6 text-center text-xs uppercase tracking-[0.3em] text-slate-500">No hiccups yet.</div>`;
        return;
    }
    container.innerHTML = rows.map((h) => hiccupCardHtml(h, options)).join('');
}

function renderMyHiccupsTable() {
    const tbody = document.querySelector('#my-hiccups-table tbody');
    if (!tbody && !document.getElementById('raised-by-cards')) return;
    let filtered = myHiccupsData;
    filtered = filtered.filter((entry) =>
        matchesCurrentUser(entry.raised_by, entry.raised_by_name)
    );
    const statusValue = statusFilter?.value;
    const typeValue = typeFilter?.value;
    if (statusValue) {
        filtered = filtered.filter((entry) => entry.status === statusValue);
    }
    if (typeValue) {
        filtered = filtered.filter((entry) => entry.hiccup_type === typeValue);
    }
    const searchValue = globalSearchInput?.value?.trim();
    if (searchValue) {
        filtered = filtered.filter((entry) => matchesGlobalSearch(entry, searchValue));
    }
    renderHiccupCards('raised-by-cards', filtered, { displayRaisedAgainst: true });
    if (tbody) {
        if (filtered.length === 0) {
            tbody.innerHTML = `<tr><td colspan="${listColumnCount}" class="px-4 py-4 text-center text-xs uppercase tracking-[0.3em] text-slate-400">No hiccups yet.</td></tr>`;
        } else {
            tbody.innerHTML = filtered.map((h) => summaryRowHtml(h, true, false)).join('');
        }
    }
}

function renderAssignedTable(data) {
    const assignedBody = document.querySelector('#assigned-table tbody');
    if (!assignedBody && !document.getElementById('against-me-cards')) return;
    const rows = Array.isArray(data) ? data : [];
    const assigned = rows.filter((h) =>
        matchesCurrentUser(h.raised_against, h.raised_against_name)
    );
    if (assigned.length === 0) {
        assignedBody.innerHTML = `<tr><td colspan="${listColumnCount}" class="px-4 py-4 text-center text-xs uppercase tracking-[0.3em] text-slate-400">No assignments yet.</td></tr>`;
        renderHiccupCards('against-me-cards', [], {
            displayRaisedAgainst: false,
        });
        return;
    }
    const searchValue = globalSearchInput?.value?.trim();
    const filteredAssigned = searchValue ? assigned.filter((entry) => matchesGlobalSearch(entry, searchValue)) : assigned;
    if (filteredAssigned.length === 0) {
        assignedBody.innerHTML = `<tr><td colspan="${listColumnCount}" class="px-4 py-4 text-center text-xs uppercase tracking-[0.3em] text-slate-400">No assignments yet.</td></tr>`;
        renderHiccupCards('against-me-cards', [], {
            displayRaisedAgainst: false,
        });
        return;
    }
    renderHiccupCards('against-me-cards', filteredAssigned, {
        displayRaisedAgainst: false,
        allowRespond: (h) => h.status !== 'Closed' && !h.response_text,
        allowNcView: (h) => h.status === 'Escalated to NC' || h.escalated_by,
        ncReadonly: true,
    });
    if (assignedBody) {
        assignedBody.innerHTML = filteredAssigned
            .map((h) => {
                const canRespond = h.status !== 'Closed' && !h.response_text;
                return summaryRowHtml(h, true, false, {
                    displayRaisedAgainst: false,
                    allowNcView: h.status === 'Escalated to NC' || h.escalated_by,
                    ncReadonly: true,
                    allowRespond: canRespond,
                });
            })
            .join('');
    }
}

function applyManagementFilters(rows) {
    let filtered = rows;
    const statusValue = mgmtStatusFilter?.value;
    const typeValue = mgmtTypeFilter?.value;
    const rootValue = mgmtRootFilter?.value;
    if (statusValue) {
        filtered = filtered.filter((entry) => entry.status === statusValue);
    }
    if (typeValue) {
        filtered = filtered.filter((entry) => entry.hiccup_type === typeValue);
    }
    if (rootValue) {
        filtered = filtered.filter((entry) => entry.root_cause_category === rootValue);
    }
    return filtered;
}

function renderManagementTable(data) {
    const mgmtBody = document.querySelector('#management-table tbody');
    if (!mgmtBody) return;
    const rows = Array.isArray(data) ? data : [];
    const filtered = applyManagementFilters(rows);
    const assignedFiltered = assignedViewMode
        ? filtered.filter(
              (entry) =>
                  entry.status === 'Escalated to NC' &&
                  entry.nc_assigned_staff_id &&
                  String(entry.nc_assigned_staff_id) === String(currentUserId)
          )
        : filtered;
    const mgmtSearchValue = mgmtGlobalSearchInput?.value?.trim();
    const finalFiltered = mgmtSearchValue
        ? assignedFiltered.filter((entry) => matchesGlobalSearch(entry, mgmtSearchValue))
        : assignedFiltered;
    renderHiccupCards('assigned-nc-cards', assignedViewMode ? finalFiltered : [], {
        displayRaisedAgainst: true,
        includeMgmtActions: showManagementActions,
        allowNcView: (h) => h.status === 'Escalated to NC' || h.escalated_by,
        ncReadonly: true,
    });
    if (finalFiltered.length === 0) {
        mgmtBody.innerHTML = `<tr><td colspan="${managementColumnCount}" class="px-4 py-4 text-center text-xs uppercase tracking-[0.3em] text-slate-400">No hiccups yet.</td></tr>`;
        return;
    }
    mgmtBody.innerHTML = finalFiltered
        .map((h) => summaryRowHtml(h, showManagementActions, showManagementActions))
        .join('');
}

function renderAllTables(data) {
    const rows = Array.isArray(data) ? data : [];
    myHiccupsData = rows;
    renderMyHiccupsTable();
    renderAssignedTable(rows);
    renderManagementTable(rows);
}

if (statusFilter) {
    statusFilter.addEventListener('change', renderMyHiccupsTable);
}
if (typeFilter) {
    typeFilter.addEventListener('change', renderMyHiccupsTable);
}
resetFilters?.addEventListener('click', () => {
    if (statusFilter) statusFilter.value = '';
    if (typeFilter) typeFilter.value = '';
    if (globalSearchInput) globalSearchInput.value = '';
    renderMyHiccupsTable();
    renderAssignedTable(myHiccupsData);
});

const mgmtSelectFilters = [mgmtStatusFilter, mgmtTypeFilter, mgmtRootFilter];
mgmtSelectFilters.forEach((filterEl) => {
    if (filterEl) {
        filterEl.addEventListener('change', () => renderManagementTable(myHiccupsData));
    }
});
globalSearchInput?.addEventListener('input', () => {
    renderMyHiccupsTable();
    renderAssignedTable(myHiccupsData);
});
mgmtGlobalSearchInput?.addEventListener('input', () => renderManagementTable(myHiccupsData));
mgmtResetFilters?.addEventListener('click', () => {
    if (mgmtStatusFilter) mgmtStatusFilter.value = '';
    if (mgmtTypeFilter) mgmtTypeFilter.value = '';
    if (mgmtRootFilter) mgmtRootFilter.value = '';
    if (mgmtGlobalSearchInput) mgmtGlobalSearchInput.value = '';
    renderManagementTable(myHiccupsData);
});

function toggleHiccupTab(target) {
    const raisedSection = document.getElementById('raised-by-section');
    const againstSection = document.getElementById('against-me-section');
    const raisedCards = document.getElementById('raised-by-cards');
    const againstCards = document.getElementById('against-me-cards');
    const raisedTab = document.getElementById('tab-raised-by');
    const againstTab = document.getElementById('tab-against-me');
    const isRaised = target === 'raised';
    if (raisedSection) raisedSection.classList.toggle('hidden', !isRaised);
    if (againstSection) againstSection.classList.toggle('hidden', isRaised);
    if (raisedCards) raisedCards.classList.toggle('hidden', !isRaised);
    if (againstCards) againstCards.classList.toggle('hidden', isRaised);
    const updateTabStyles = (tabEl, active) => {
        if (!tabEl) return;
        tabEl.classList.toggle('bg-tealbrand', active);
        tabEl.classList.toggle('text-white', active);
        tabEl.classList.toggle('border-tealbrand', active);
        tabEl.classList.toggle('bg-white', !active);
        tabEl.classList.toggle('text-slate-700', !active);
        tabEl.classList.toggle('border-slate-200', !active);
    };
    updateTabStyles(raisedTab, isRaised);
    updateTabStyles(againstTab, !isRaised);
}

function setupHiccupTabs() {
    const raisedTab = document.getElementById('tab-raised-by');
    const againstTab = document.getElementById('tab-against-me');
    if (!raisedTab && !againstTab) {
        return;
    }
    raisedTab?.addEventListener('click', () => toggleHiccupTab('raised'));
    againstTab?.addEventListener('click', () => toggleHiccupTab('against'));
    toggleHiccupTab('raised');
}

async function loadMyHiccups() {
    if (!hasHiccupTables) {
        return;
    }
    showLoading('Loading hiccups...');
    try {
        const endpoint = assignedViewMode
            ? '/api/hiccups/assigned'
            : window.managementView
            ? '/api/hiccups/all'
            : '/api/hiccups';
        const data = await fetchJSON(endpoint);
        await hydrateRaisedAgainstNames(data);
        renderAllTables(data);
    } catch (err) {
        console.error('Unable to load hiccups', err);
        if (err?.status === 401) {
            clearAuthState();
            window.location.href = '/login';
            return;
        }
        if (err?.status === 404 || err?.status === 204) {
            renderAllTables([]);
            return;
        }
        renderAllTables([]);
        await showAlert({
            icon: 'error',
            title: 'Unable to load hiccups',
            text: err?.message || 'Please refresh the page.',
        });
    } finally {
        closeLoading();
    }
}

function ensureStatusModal() {
    const existing = document.getElementById('status-modal');
    if (existing) {
        return existing;
    }
    const wrapper = document.createElement('div');
    wrapper.innerHTML = `
        <div class="status-modal hidden" id="status-modal" aria-hidden="true">
            <div class="status-modal__backdrop" data-modal-close></div>
            <div class="status-modal__card" role="dialog" aria-labelledby="status-modal-title">
                <h2 class="status-modal__title" id="status-modal-title"></h2>
                <div class="status-modal__body"></div>
                <div class="status-modal__actions">
                    <button type="button" class="status-modal__btn status-modal__btn--ghost" data-modal-close>Cancel</button>
                    <button type="button" class="status-modal__btn status-modal__btn--primary" data-modal-confirm>Submit</button>
                </div>
            </div>
        </div>
    `;
    const modal = wrapper.firstElementChild;
    document.body.appendChild(modal);
    return modal;
}

function renderStatusField(field) {
    const type = field.type || 'textarea';
    const placeholder = escapeHtml(field.placeholder || '');
    const labelText = field.label ? escapeHtml(field.label) : '';
    if (type === 'checkbox_group') {
        const selectedValues = Array.isArray(field.value) ? field.value.map((item) => String(item)) : [];
        const options = (field.options || [])
            .map((option, index) => {
                const optionValue = String(option.value ?? option.label);
                const isChecked = selectedValues.includes(optionValue) ? 'checked' : '';
                const otherAttr =
                    optionValue === 'other' && field.otherFieldKey
                        ? `data-other-target="${field.id}-other-wrapper"`
                        : '';
                return `
                    <label class="status-modal__checkbox" for="${field.id}-${index}">
                        <input
                            type="checkbox"
                            id="${field.id}-${index}"
                            value="${escapeHtml(optionValue)}"
                            ${isChecked}
                            ${otherAttr}
                        >
                        ${escapeHtml(option.label)}
                    </label>
                `;
            })
            .join('');
        const otherWrapper = field.otherFieldKey
            ? `
                <div class="status-modal__other-input" id="${field.id}-other-wrapper">
                    <label class="status-modal__label" for="${field.id}-other">${escapeHtml(
                        field.otherLabel || 'Other details'
                    )}</label>
                    <input
                        id="${field.id}-other"
                        type="text"
                        class="status-modal__input"
                        placeholder="${escapeHtml(field.otherPlaceholder || 'Please specify')}"
                        value="${escapeHtml(field.otherValue ?? '')}"
                    />
                </div>
            `
            : '';
        return `
            <div class="status-modal__field-group">
                <p class="status-modal__label">${labelText}</p>
                <div class="status-modal__checkbox-group" id="${field.id}">
                    ${options}
                </div>
                ${otherWrapper}
            </div>
        `;
    }
    const labelHtml = labelText
        ? `<label class="status-modal__label" for="${field.id}">${labelText}</label>`
        : '';
    const suggestionList =
        field.suggestions && field.suggestions.listEnabled
            ? `<datalist id="${field.id}-list"></datalist>`
            : '';
    const suggestionAttr = field.suggestions && field.suggestions.listEnabled ? `list="${field.id}-list"` : '';
    const readonlyAttr = field.readonly ? 'readonly' : '';
    const disabledAttr = field.disabled ? 'disabled' : '';
    if (type === 'hidden') {
        const hiddenValue = escapeHtml(String(field.value ?? ''));
        return `<input id="${field.id}" type="hidden" value="${hiddenValue}" />`;
    }
    if (type === 'text' || type === 'date') {
        const rawValue = field.value ?? '';
        const valueAttr = `value="${escapeHtml(String(rawValue))}"`;
        return `
            <div class="status-modal__field-group">
                ${labelHtml}
                <input
                    id="${field.id}"
                    type="${type}"
                    class="status-modal__input"
                    placeholder="${placeholder}"
                    ${suggestionAttr}
                    ${valueAttr}
                    ${readonlyAttr}
                    ${disabledAttr}
                />
                ${suggestionList}
            </div>
        `;
    }
    const textareaValue = escapeHtml(String(field.value ?? ''));
    const textareaReadonlyAttr = field.readonly ? 'readonly' : '';
    return `
        <div class="status-modal__field-group">
            ${labelHtml}
            <textarea
                id="${field.id}"
                class="status-modal__textarea"
                placeholder="${placeholder}"
                ${textareaReadonlyAttr}
            >${textareaValue}</textarea>
        </div>
    `;
}

function toggleCheckboxOtherInput(checkbox) {
    const targetId = checkbox.dataset.otherTarget;
    if (!targetId) {
        return;
    }
    const wrapper = document.getElementById(targetId);
    if (!wrapper) {
        return;
    }
    const shouldShow = checkbox.checked;
    wrapper.classList.toggle('visible', shouldShow);
    if (!shouldShow) {
        const otherInput = wrapper.querySelector('input, textarea');
        if (otherInput) {
            otherInput.value = '';
        }
    }
}

function setupCheckboxOtherInputs(modal) {
    const handlers = [];
    const checkboxes = modal.querySelectorAll('[data-other-target]');
    checkboxes.forEach((checkbox) => {
        const handler = () => toggleCheckboxOtherInput(checkbox);
        checkbox.addEventListener('change', handler);
        handlers.push({ checkbox, handler });
        handler();
    });
    return handlers;
}

async function fetchStaffSuggestions(query) {
    if (!query || query.length < 2) {
        return [];
    }
    try {
        const params = new URLSearchParams({ q: query });
        const res = await fetch(`/api/staff/suggest?${params.toString()}`, {
            headers: authHeaders(),
        });
        if (!res.ok) {
            return [];
        }
        const list = await res.json();
        if (!Array.isArray(list)) {
            return [];
        }
        return list
            .filter((item) => item && item.name)
            .map((item) => ({
                id: item.id,
                name: String(item.name),
            }));
    } catch (err) {
        console.error('Failed to load staff suggestions', err);
        return [];
    }
}

function attachSuggestionHandlers(modal, fields) {
    const handlers = [];
    fields.forEach((field) => {
        if (!field.suggestions || !field.suggestions.listEnabled) {
            return;
        }
        const input = modal.querySelector(`#${field.id}`);
        if (!input) {
            return;
        }
        const datalist = modal.querySelector(`#${field.id}-list`);
        const hiddenInput = field.hiddenTargetId
            ? modal.querySelector(`#${field.hiddenTargetId}`)
            : null;
        let timer = null;
        let suggestionsCache = [];
        const applyHiddenValue = () => {
            if (!hiddenInput) {
                return;
            }
            const value = input.value.trim().toLowerCase();
            const match = suggestionsCache.find(
                (item) => item.name.toLowerCase() === value
            );
            hiddenInput.value = match ? String(match.id) : '';
        };
        const handler = () => {
            const value = input.value.trim();
            if (value.length < (field.suggestions.minLength ?? 2)) {
                if (datalist) {
                    datalist.innerHTML = '';
                }
                suggestionsCache = [];
                applyHiddenValue();
                return;
            }
            clearTimeout(timer);
            timer = setTimeout(async () => {
                const list = await fetchStaffSuggestions(value);
                if (datalist) {
                    datalist.innerHTML = list
                        .map(
                            (item) => `<option value="${escapeHtml(
                                item.name
                            )}" data-id="${escapeHtml(String(item.id))}"></option>`
                        )
                        .join('');
                }
                suggestionsCache = list;
                applyHiddenValue();
            }, field.suggestions.debounce ?? SUGGESTION_DEBOUNCE);
        };
        applyHiddenValue();
        input.addEventListener('input', handler);
        handlers.push({ input, handler, timer, datalist });
    });
    return handlers;
}

function showStatusModal({ title, confirmText, fields }) {
    const modal = ensureStatusModal();
    const titleEl = modal.querySelector('.status-modal__title');
    const bodyEl = modal.querySelector('.status-modal__body');
    const confirmBtn = modal.querySelector('[data-modal-confirm]');
    const closeTriggers = modal.querySelectorAll('[data-modal-close]');
    titleEl.textContent = title;
    bodyEl.innerHTML = fields.map(renderStatusField).join('');
    confirmBtn.textContent = confirmText;
    const otherHandlers = setupCheckboxOtherInputs(modal);
    const suggestionHandlers = attachSuggestionHandlers(modal, fields);
    bodyEl.scrollTop = 0;

    return new Promise((resolve) => {
        const cleanup = () => {
            modal.classList.add('hidden');
            modal.setAttribute('aria-hidden', 'true');
            confirmBtn.disabled = false;
            modal
                .querySelectorAll('.status-modal__checkbox-group--invalid')
                .forEach((group) => group.classList.remove('status-modal__checkbox-group--invalid'));
            modal
                .querySelectorAll('.status-modal__textarea--invalid')
                .forEach((el) => el.classList.remove('status-modal__textarea--invalid'));
            modal
                .querySelectorAll('.status-modal__other-input.visible')
                .forEach((wrapper) => wrapper.classList.remove('visible'));
            closeTriggers.forEach((btn) => btn.removeEventListener('click', onCancel));
            confirmBtn.removeEventListener('click', onConfirm);
            otherHandlers.forEach(({ checkbox, handler }) => {
                checkbox.removeEventListener('change', handler);
            });
            suggestionHandlers.forEach(({ input, handler, timer, datalist }) => {
                input.removeEventListener('input', handler);
                if (timer) {
                    clearTimeout(timer);
                }
                if (datalist && datalist.parentNode) {
                    datalist.innerHTML = '';
                }
            });
        };

        const onCancel = () => {
            cleanup();
            resolve(null);
        };

        const onConfirm = () => {
            const values = {};
            for (const field of fields) {
                const type = field.type || 'textarea';
                if (type === 'checkbox_group') {
                    const group = modal.querySelector(`#${field.id}`);
                    const checkedBoxes = group
                        ? group.querySelectorAll('input[type="checkbox"]:checked')
                        : [];
                    const selections = Array.from(checkedBoxes).map((checkbox) => checkbox.value);
                    if (field.required && selections.length === 0) {
                        group?.classList.add('status-modal__checkbox-group--invalid');
                        group?.scrollIntoView({ behavior: 'smooth', block: 'center' });
                        return;
                    }
                    group?.classList.remove('status-modal__checkbox-group--invalid');
                    values[field.key] = selections;
                    if (field.otherFieldKey && selections.includes('other')) {
                        const otherInput = document.getElementById(`${field.id}-other`);
                        const otherValue = otherInput?.value.trim();
                        if (otherValue) {
                            values[field.otherFieldKey] = otherValue;
                        }
                    }
                    continue;
                }
                const input = document.getElementById(field.id);
                const rawValue = input?.value ?? '';
                const value = rawValue.toString().trim();
                if (field.required && !value) {
                    input?.focus();
                    input?.classList.add('status-modal__textarea--invalid');
                    return;
                }
                input?.classList.remove('status-modal__textarea--invalid');
                values[field.key] = value;
            }
            cleanup();
            resolve(values);
        };

        closeTriggers.forEach((btn) => btn.addEventListener('click', onCancel));
        confirmBtn.addEventListener('click', onConfirm);
        modal.classList.remove('hidden');
        modal.setAttribute('aria-hidden', 'false');
        const firstInput = modal.querySelector('.status-modal__textarea');
        firstInput?.focus();
    });
}

const ROOT_CAUSE_OPTIONS = [
    { value: 'lack_of_training', label: 'Lack of Training / Knowledge' },
    { value: 'ignored_instructions', label: 'Ignored instructions / coaching (empathy/listening)' },
    { value: 'time_mismanagement', label: 'Time mismanagement / carelessness' },
    { value: 'misunderstanding_process', label: 'Misunderstanding of Process / SOP' },
    { value: 'communication_gaps', label: 'Communication gaps (tone)' },
    { value: 'repeated_feedback', label: 'Repeated mistake after feedback' },
    { value: 'other', label: 'Other' },
];
const PREVENTIVE_ACTION_OPTIONS = [
    { value: 'coaching', label: 'One-on-one Coaching Session' },
    { value: 'performance_monitoring', label: 'Performance Monitoring' },
    { value: 'sop_review', label: 'SOP Review / Simplification' },
    { value: 'process_refresher', label: 'Process Refresher Training' },
    { value: 'written_warning', label: 'Written Warning / Escalation' },
    { value: 'other', label: 'Other' },
];

const ROOT_CAUSE_LABEL_MAP = new Map(
    ROOT_CAUSE_OPTIONS.map((entry) => [entry.value, entry.label])
);

function buildRootCauseSummary(flags = [], other) {
    const labels = [];
    if (Array.isArray(flags)) {
        flags.forEach((flag) => {
            const label = ROOT_CAUSE_LABEL_MAP.get(flag);
            if (label) {
                labels.push(label);
            }
        });
    }
    if (other) {
        labels.push(other);
    }
    if (labels.length) {
        return labels.join(', ');
    }
    return null;
}

const STAFF_SUGGESTION_CONFIG = {
    listEnabled: true,
    minLength: 2,
    debounce: 250,
};

function buildStaffNameFields(initial = {}) {
    const nameValue = initial.staff_name ?? initial.name ?? "";
    const idValue = initial.staff_id ?? initial.id ?? "";
    return [
        {
            id: "escalation-staff-name",
            key: "staff_name",
            label: "Staff name",
            placeholder: "Enter staff or team lead name",
            type: "text",
            suggestions: STAFF_SUGGESTION_CONFIG,
            value: nameValue,
            hiddenTargetId: "escalation-staff-id",
        },
        {
            id: "escalation-staff-id",
            key: "staff_id",
            type: "hidden",
            value: idValue,
        },
    ];
}

function buildNCEscalationFields(initial = {}, options = {}) {
    const rootFlags = Array.isArray(initial.root_cause_flags)
        ? initial.root_cause_flags.map((flag) => String(flag))
        : [];
    if (initial.root_cause_other && !rootFlags.includes('other')) {
        rootFlags.push('other');
    }
    const preventiveFlags = Array.isArray(initial.preventive_actions)
        ? initial.preventive_actions.map((flag) => String(flag))
        : [];
    if (initial.preventive_other && !preventiveFlags.includes('other')) {
        preventiveFlags.push('other');
    }
    const fields = [];
    if (options.includeStaffDisplay) {
        fields.push({
            id: 'escalation-staff-name-display',
            key: 'staff_name',
            label: 'Staff name',
            type: 'text',
            value: initial.staff_name ?? '',
            readonly: true,
        });
        fields.push({
            id: 'escalation-staff-id',
            key: 'staff_id',
            type: 'hidden',
            value: initial.staff_id ?? '',
        });
    }
    fields.push(
        {
            id: 'escalation-root-cause',
            key: 'root_cause_flags',
            label: 'Root cause analysis',
            type: 'checkbox_group',
            options: ROOT_CAUSE_OPTIONS,
            otherFieldKey: 'root_cause_other',
            otherLabel: 'Other root cause detail',
            otherPlaceholder: 'Describe the root cause if Other is selected',
            value: rootFlags,
            otherValue: initial.root_cause_other,
        },
        {
            id: 'escalation-action-plan',
            key: 'corrective_action',
            label: 'Corrective action plan',
            placeholder: 'Capture the corrective action',
            type: 'textarea',
            value: initial.corrective_action ?? '',
        },
        {
            id: 'escalation-action-by',
            key: 'corrective_action_by',
            label: 'Action taken by',
            placeholder: 'Who implemented the corrective action?',
            type: 'text',
            value: initial.corrective_action_by ?? '',
        },
        {
            id: 'escalation-action-date',
            key: 'corrective_action_date',
            label: 'Action date',
            type: 'date',
            value: initial.corrective_action_date ?? '',
        },
        {
            id: 'escalation-person-responsible',
            key: 'person_responsible',
            label: 'Person responsible',
            placeholder: 'Name of the person responsible for follow-up',
            type: 'text',
            value: initial.person_responsible ?? '',
        },
        {
            id: 'escalation-timeline',
            key: 'timeline_for_completion',
            label: 'Timeline for completion',
            placeholder: 'Month / week / date',
            type: 'text',
            value: initial.timeline_for_completion ?? '',
        },
        {
            id: 'escalation-preventive-options',
            key: 'preventive_actions',
            label: 'Preventive action',
            type: 'checkbox_group',
            options: PREVENTIVE_ACTION_OPTIONS,
            otherFieldKey: 'preventive_other',
            otherLabel: 'Other preventive action detail',
            otherPlaceholder: 'Describe the preventive action if Other is selected',
            value: preventiveFlags,
            otherValue: initial.preventive_other,
        }
    );
    return fields;
}

async function gatherStatusPayload(status) {
    if (status === 'Closed') {
        return await showStatusModal({
            title: 'Closure details',
            confirmText: 'Save',
            fields: [
                {
                    id: 'closure-notes',
                    key: 'closure_notes',
                    label: 'Closure notes',
                    placeholder: 'Describe how the hiccup was closed',
                    required: true,
                },
            ],
        });
    }
    if (status === 'Escalated to NC') {
        const staffResult = await showStatusModal({
            title: 'Escalate to NC – staff name',
            confirmText: 'Next',
            fields: buildStaffNameFields(),
        });
        if (!staffResult) {
            return null;
        }
        const detailResult = await showStatusModal({
            title: 'Escalation details',
            confirmText: 'Escalate',
            fields: buildNCEscalationFields(),
        });
        if (!detailResult) {
            return null;
        }
        const rootCauseSummary = buildRootCauseSummary(
            detailResult.root_cause_flags,
            detailResult.root_cause_other
        );
        const trimmedCorrectiveAction = detailResult.corrective_action?.trim();
        const payload = {
            escalation_form: {
                staff_name: staffResult.staff_name,
                staff_id: staffResult.staff_id,
                root_cause_flags: detailResult.root_cause_flags,
                root_cause_other: detailResult.root_cause_other,
                corrective_action_by: detailResult.corrective_action_by,
                corrective_action_date: detailResult.corrective_action_date,
                person_responsible: detailResult.person_responsible,
                timeline_for_completion: detailResult.timeline_for_completion,
                preventive_actions: detailResult.preventive_actions,
                preventive_other: detailResult.preventive_other,
            },
        };
        if (rootCauseSummary) {
            payload.root_cause = rootCauseSummary;
        }
        if (trimmedCorrectiveAction) {
            payload.corrective_action = trimmedCorrectiveAction;
        }
        return payload;
    }
    return {};
}

function renderNCSummary(formData) {
    if (!formData) return '<p class="text-sm text-slate-600">No NC data.</p>';
    const escape = (val) => escapeHtml(val || '-');
    const list = [
        ['Staff name', formData.staff_name],
        ['Root causes', Array.isArray(formData.root_cause_flags) ? formData.root_cause_flags.join(', ') : formData.root_cause_flags],
        ['Other root cause', formData.root_cause_other],
        ['Corrective action', formData.corrective_action],
        ['Action by', formData.corrective_action_by],
        ['Action date', formData.corrective_action_date],
        ['Person responsible', formData.person_responsible],
        ['Timeline', formData.timeline_for_completion],
        ['Preventive actions', Array.isArray(formData.preventive_actions) ? formData.preventive_actions.join(', ') : formData.preventive_actions],
        ['Preventive other', formData.preventive_other],
    ];
    return `
        <div class="grid gap-3 text-left text-sm text-slate-800">
            ${list
                .map(
                    ([label, value]) => `
                        <div class="rounded-2xl border border-slate-100 bg-slate-50/80 p-3">
                            <p class="text-[10px] uppercase tracking-[0.3em] text-slate-500">${escape(label)}</p>
                            <p class="mt-1 text-sm font-semibold text-slate-900">${escape(value)}</p>
                        </div>
                    `
                )
                .join('')}
        </div>
    `;
}

function showNCSummaryModal(formData) {
    const existing = document.getElementById('nc-view-modal');
    if (existing) existing.remove();
    const wrapper = document.createElement('div');
    wrapper.id = 'nc-view-modal';
    wrapper.innerHTML = `
        <div class="nc-view-backdrop"></div>
        <div class="nc-view-card" role="dialog" aria-label="NC Escalation">
            <div class="nc-view-header">
                <h3>NC escalation details</h3>
                <button type="button" class="nc-view-close" aria-label="Close">×</button>
            </div>
            <div class="nc-view-body">${renderNCSummary(formData)}</div>
            <div class="nc-view-footer">
                <button type="button" class="nc-view-close">Close</button>
            </div>
        </div>
    `;
    document.body.appendChild(wrapper);
    const close = () => wrapper.remove();
    wrapper.querySelectorAll('.nc-view-close, .nc-view-backdrop').forEach((el) =>
        el.addEventListener('click', close)
    );
}

// lightweight styles for nc summary modal
const ncModalStyles = `
#nc-view-modal { position: fixed; inset: 0; z-index: 9999; display: grid; place-items: center; }
#nc-view-modal .nc-view-backdrop { position: absolute; inset: 0; background: rgba(15,23,42,0.35); backdrop-filter: blur(2px); }
#nc-view-modal .nc-view-card { position: relative; max-width: 520px; width: 92vw; max-height: 70vh; overflow-y: auto; background: #fff; border-radius: 18px; box-shadow: 0 18px 38px rgba(15,23,42,0.18); padding: 16px; }
#nc-view-modal .nc-view-header { display: flex; align-items: center; justify-content: space-between; gap: 8px; margin-bottom: 10px; }
#nc-view-modal h3 { margin: 0; font-size: 18px; font-weight: 800; color: #0f172a; }
#nc-view-modal .nc-view-close { border: none; background: #0db29c; color: #fff; border-radius: 10px; padding: 8px 12px; font-weight: 700; cursor: pointer; }
#nc-view-modal .nc-view-close:hover { background: #0a7f6f; }
#nc-view-modal .nc-view-body { max-height: 52vh; overflow-y: auto; }
#nc-view-modal .nc-view-footer { display: flex; justify-content: flex-end; margin-top: 12px; }
#nc-view-modal .nc-view-card::-webkit-scrollbar { width: 6px; }
#nc-view-modal .nc-view-card::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 999px; }
#nc-view-modal .nc-view-card::-webkit-scrollbar-thumb:hover { background: #94a3b8; }
#nc-view-modal .nc-view-card::-webkit-scrollbar-track { background: transparent; }
`;
if (!document.getElementById('nc-view-modal-style')) {
    const style = document.createElement('style');
    style.id = 'nc-view-modal-style';
    style.textContent = ncModalStyles;
    document.head.appendChild(style);
}

async function openNCEscalationForm(hiccupId, options = {}) {
    const { readonly = false } = options;
    showLoading('Loading NC form...');
    let formData;
    try {
        formData = await fetchJSON(`/api/hiccups/${hiccupId}/nc-form`);
    } catch (err) {
        await showAlert({
            icon: 'error',
            title: 'Unable to load NC form',
            text: err?.message || 'Please try again.',
        });
        return;
    } finally {
        closeLoading();
    }
    if (readonly) {
        closeLoading();
        showNCSummaryModal(formData);
        return;
    }

    const detailResult = await showStatusModal({
        title: 'NC escalation details',
        confirmText: 'Save',
        fields: buildNCEscalationFields(formData, { includeStaffDisplay: true }),
    });
    if (!detailResult) {
        return;
    }

    const closeChoice = await confirmDialog({
        title: 'Save or close?',
        text: 'Save NC details only, or save and close the hiccup with closure notes.',
        confirmButtonText: 'Save & Close',
        cancelButtonText: 'Save Only',
        showCancelButton: true,
    });

    if (closeChoice?.isConfirmed) {
        const closurePayload = await showStatusModal({
            title: 'Closure notes',
            confirmText: 'Close',
            fields: [
                {
                    id: 'closure-notes',
                    key: 'closure_notes',
                    label: 'Closure notes',
                    placeholder: 'Summarize resolution',
                    required: true,
                    type: 'textarea',
                },
            ],
        });
        if (!closurePayload) {
            return;
        }
        showLoading('Saving & closing hiccup...');
        try {
            // save NC form first
            await fetchJSON(`/api/hiccups/${hiccupId}/nc-form`, {
                method: 'PATCH',
                body: JSON.stringify(detailResult),
            });
            // then close with closure notes
            await fetchJSON(`/api/hiccups/${hiccupId}/status`, {
                method: 'PATCH',
                body: JSON.stringify({
                    status: 'Closed',
                    closure_notes: closurePayload.closure_notes,
                }),
            });
            await loadMyHiccups?.();
            await showAlert({
                icon: 'success',
                title: 'Hiccup closed',
                text: 'NC form saved and hiccup closed.',
                timer: 1200,
                showConfirmButton: false,
            });
        } catch (err) {
            await showAlert({
                icon: 'error',
                title: 'Unable to close',
                text: err?.message || 'Please try again.',
            });
        } finally {
            closeLoading();
        }
        return;
    }

    showLoading('Saving NC form...');
    try {
        await fetchJSON(`/api/hiccups/${hiccupId}/nc-form`, {
            method: 'PATCH',
            body: JSON.stringify(detailResult),
        });
        await loadMyHiccups();
        await showAlert({
            icon: 'success',
            title: 'NC form updated',
            text: 'Escalation details saved.',
            timer: 1200,
            showConfirmButton: false,
        });
    } catch (err) {
        await showAlert({
            icon: 'error',
            title: 'Unable to save NC form',
            text: err?.message || 'Please try again.',
        });
    } finally {
        closeLoading();
    }
}

async function quickStatus(id, status) {
    let statusExtras = null;
    try {
        statusExtras = await gatherStatusPayload(status);
    } catch (err) {
        return;
    }
    if (statusExtras === null) {
        return;
    }
    showLoading('Updating status...');
    try {
        const res = await fetch(`/api/hiccups/${id}/status`, {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json',
                ...authHeaders(),
            },
            body: JSON.stringify({ status, ...(statusExtras ?? {}) }),
        });
        if (!res.ok) {
            const message = await formatError(res);
            throw new Error(message || 'Unable to update status');
        }
        await loadMyHiccups();
        await showAlert({
            icon: 'success',
            title: 'Status updated',
            text: `Marked ${status}`,
            timer: 1200,
            showConfirmButton: false,
        });
    } catch (err) {
        await showAlert({
            icon: 'error',
            title: 'Unable to update status',
            text: err?.message || 'Try again later.',
        });
    } finally {
        closeLoading();
    }
}

const form = document.getElementById('hiccup-form');
if (form) {
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        if (!form.checkValidity()) {
            form.reportValidity();
            return;
        }
        const data = new FormData(form);
        const hiccupTypeValue = data.get('hiccup_type');
        const raisedDeptRaw = String(data.get('raised_against_department') ?? '').trim();
        const raisedDeptNameRaw = String(data.get('raised_against_department_name') ?? '').trim();
        if (!raisedDeptRaw && !raisedDeptNameRaw) {
            await showAlert({
                icon: 'error',
                title: 'Department required',
                text: 'Please provide a raised-against department name or select staff to auto-fill it.',
            });
            document.getElementById('raised-dept-name')?.focus();
            return;
        }
        if (raisedDeptRaw) {
            data.set('raised_against_department', raisedDeptRaw);
        } else {
            data.delete('raised_against_department');
        }
        if (raisedDeptNameRaw) {
            data.set('raised_against_department_name', raisedDeptNameRaw);
        } else {
            data.delete('raised_against_department_name');
        }
        const raisedAgainstValue = String(data.get('raised_against') ?? '').trim();
        const raisedAgainstNameValue = String(data.get('raised_against_name') ?? '').trim();
        if (hiccupTypeValue === 'Person Related' && !raisedAgainstValue) {
            await showAlert({
                icon: 'error',
                title: 'Raised against missing',
                text: 'Please select who this hiccup is raised against when it is person related.',
            });
            document.getElementById('raised-against-name')?.focus();
            return;
        }
        if (hiccupTypeValue === 'System Related') {
            if (raisedAgainstNameValue) {
                await showAlert({
                    icon: 'error',
                    title: 'System hiccup',
                    text: 'System hiccups must not specify a person in "Raised Against".',
                });
                document.getElementById('raised-against-name')?.focus();
                return;
            }
            data.delete('raised_against');
            data.delete('raised_against_name');
        }
        showLoading('Submitting hiccup...');
        try {
            const res = await fetch('/api/hiccups', { method: 'POST', headers: authHeaders(), body: data });
            if (!res.ok) {
                const message = await formatError(res);
                throw new Error(message || 'Failed to create hiccup');
            }
            const json = await res.json();
            form.reset();
            await showAlert({
                icon: 'success',
                title: 'Hiccup raised',
                text: `Created ${json.hiccup_id}`,
                timer: 1200,
                showConfirmButton: false,
            });
            await loadMyHiccups();
        } catch (err) {
            await showAlert({
                icon: 'error',
                title: 'Unable to raise hiccup',
                text: err?.message || 'Please try again after checking the form.',
            });
            console.error(err);
        } finally {
            closeLoading();
        }
    });
}

document.addEventListener('click', async (event) => {
    const ncTrigger = event.target.closest('[data-behavior="view-nc"]');
    if (ncTrigger) {
        event.preventDefault();
        const hiccupId = ncTrigger.dataset.hiccup;
        const readonly = ncTrigger.dataset.ncReadonly === 'true';
        await openNCEscalationForm(hiccupId, { readonly });
        return;
    }

    const respondTrigger = event.target.closest('[data-behavior="respond"]');
    if (respondTrigger) {
        event.preventDefault();
        const hiccupId = respondTrigger.dataset.hiccup;
        if (hiccupId) {
            window.location.href = `/hiccups/${hiccupId}`;
        }
        return;
    }

    const actionButton = event.target.closest('.mgmt-pill');
    if (actionButton) {
        event.preventDefault();
        event.stopPropagation();
        const hiccupId = actionButton.dataset.hiccup;
        const behavior = actionButton.dataset.behavior;
        const status = actionButton.dataset.status;
        const group = actionButton.closest('.mgmt-action-group');
        group?.classList.remove('open');
        group?.querySelector('.mgmt-toggle')?.setAttribute('aria-expanded', 'false');
        if (status) {
            await quickStatus(hiccupId, status);
        }
        return;
    }
    const detailBtn = event.target.closest('[data-hiccup-detail]');
    if (detailBtn) {
        event.preventDefault();
        const hiccupId = detailBtn.dataset.hiccupDetail;
        const hiccup = myHiccupsData.find((h) => h.hiccup_id === hiccupId);
        if (hiccup) {
            presentHiccupDetails(hiccup);
        }
        document.querySelectorAll('.mgmt-action-group.open').forEach((group) => {
            group.classList.remove('open');
            group.querySelector('.mgmt-toggle')?.setAttribute('aria-expanded', 'false');
        });
        return;
    }
    const actionToggle = event.target.closest('.mgmt-toggle');
    if (actionToggle) {
        event.preventDefault();
        event.stopPropagation();
        const group = actionToggle.closest('.mgmt-action-group');
        if (group) {
            const isOpen = group.classList.toggle('open');
            actionToggle.setAttribute('aria-expanded', isOpen);
            document.querySelectorAll('.mgmt-action-group.open').forEach((other) => {
                if (other !== group) {
                    other.classList.remove('open');
                    other.querySelector('.mgmt-toggle')?.setAttribute('aria-expanded', 'false');
                }
            });
        }
        return;
    }
    if (!event.target.closest('.mgmt-action-group')) {
        document.querySelectorAll('.mgmt-action-group.open').forEach((group) => {
            group.classList.remove('open');
            group.querySelector('.mgmt-toggle')?.setAttribute('aria-expanded', 'false');
        });
    }
});

document.addEventListener('DOMContentLoaded', () => {
    setupHiccupTabs();
    if (typeof loadMyHiccups === 'function') {
        loadMyHiccups();
    }
});
