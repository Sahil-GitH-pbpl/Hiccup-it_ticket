let myHiccupsData = [];
const statusFilter = document.getElementById('filter-status');
const typeFilter = document.getElementById('filter-type');
const dateFromFilter = document.getElementById('filter-date-from');
const dateToFilter = document.getElementById('filter-date-to');
const escalatedFilter = document.getElementById('filter-escalated');
const overdueFilter = document.getElementById('filter-overdue');
const responseBlockedFilter = document.getElementById('filter-response-blocked');
const resetFilters = document.getElementById('reset-filters');
const globalSearchInput = document.getElementById('global-hiccup-search');
const mgmtStatusFilter = document.getElementById('mgmt-filter-status');
const mgmtTypeFilter = document.getElementById('mgmt-filter-type');
const mgmtRootFilter = document.getElementById('mgmt-filter-root');
const mgmtDateFromFilter = document.getElementById('mgmt-date-from');
const mgmtDateToFilter = document.getElementById('mgmt-date-to');
const mgmtEscalatedFilter = document.getElementById('mgmt-filter-escalated');
const mgmtOverdueFilter = document.getElementById('mgmt-filter-overdue');
const mgmtResponseBlockedFilter = document.getElementById('mgmt-filter-response-blocked');
const mgmtGlobalSearchInput = document.getElementById('mgmt-global-hiccup-search');
const mgmtResetFilters = document.getElementById('mgmt-reset-filters');

const summaryColumnCount = 5;
const actionsColumnCount = 0;
const listColumnCount = summaryColumnCount;
const PAGE_SIZE_STORAGE_KEY = 'hiccupPageSize';
const PAGE_SIZE_OPTIONS = [50, 100, 200];

function getSavedPageSize() {
    const saved = Number(window.localStorage.getItem(PAGE_SIZE_STORAGE_KEY) || '');
    return PAGE_SIZE_OPTIONS.includes(saved) ? saved : 50;
}

let hiccupPageSize = getSavedPageSize();
let raisedListState = { items: [], page: 1, page_size: hiccupPageSize, total: 0, total_pages: 1 };
let assignedListState = { items: [], page: 1, page_size: hiccupPageSize, total: 0, total_pages: 1 };
let managementListState = { items: [], page: 1, page_size: hiccupPageSize, total: 0, total_pages: 1 };
const paginationState = {
    raised: 1,
    against: 1,
    management: 1,
    assigned: 1,
};
const showManagementActions = Boolean(window.managementActionsEnabled);
const assignedViewMode = Boolean(window.assignedView);
const bulkCloseEnabled = Boolean(showManagementActions && document.getElementById('bulk-close-bar'));
const managementColumnCount = summaryColumnCount + (bulkCloseEnabled ? 1 : 0) + (showManagementActions ? actionsColumnCount : 0);
const currentUserId = window.currentUserId || (window.currentUser && window.currentUser.user_id) || null;
const currentUserName = (window.currentUser && window.currentUser.name) || '';
let departmentCache = null;
const hasHiccupTables =
    Boolean(document.querySelector('#my-hiccups-table')) ||
    Boolean(document.querySelector('#management-table')) ||
    Boolean(document.querySelector('#assigned-table'));
let activeFilterDrawerId = null;
const DENSITY_STORAGE_KEY = 'hiccupDensityMode';
const SEARCH_INPUT_DEBOUNCE = 180;
let mySearchTimer = null;
let mgmtSearchTimer = null;
let latestLoadRequestId = 0;
const selectedBulkCloseIds = new Set();
const expandedHiccupByScope = {
    raised: null,
    against: null,
    management: null,
    assigned: null,
};

function getSavedDensityMode() {
    const saved = window.localStorage.getItem(DENSITY_STORAGE_KEY);
    return saved === 'compact' ? 'compact' : 'comfortable';
}

function applyDensityMode(mode) {
    const compact = mode === 'compact';
    document.body.classList.toggle('hiccup-density-compact', compact);
    window.localStorage.setItem(DENSITY_STORAGE_KEY, compact ? 'compact' : 'comfortable');
    document.querySelectorAll('[data-density-label]').forEach((el) => {
        el.textContent = compact ? 'Comfort' : 'Compact';
    });
}

function toggleDensityMode() {
    const current = getSavedDensityMode();
    applyDensityMode(current === 'compact' ? 'comfortable' : 'compact');
}

function debounceRender(timerRefName, callback, delay = SEARCH_INPUT_DEBOUNCE) {
    const existingTimer = timerRefName === 'my' ? mySearchTimer : mgmtSearchTimer;
    if (existingTimer) {
        window.clearTimeout(existingTimer);
    }
    const nextTimer = window.setTimeout(() => {
        callback();
        if (timerRefName === 'my') {
            mySearchTimer = null;
        } else {
            mgmtSearchTimer = null;
        }
    }, delay);
    if (timerRefName === 'my') {
        mySearchTimer = nextTimer;
    } else {
        mgmtSearchTimer = nextTimer;
    }
}

function defaultListState(page = 1) {
    return {
        items: [],
        page,
        page_size: hiccupPageSize,
        total: 0,
        total_pages: 1,
        start: 0,
        end: 0,
    };
}

function parseBooleanParam(value) {
    if (typeof value !== 'string') {
        return false;
    }
    const normalized = value.trim().toLowerCase();
    return normalized === 'true' || normalized === '1' || normalized === 'yes' || normalized === 'on';
}

function hydrateManagementStateFromUrl() {
    const params = new URLSearchParams(window.location.search);
    const pageValue = Number(params.get('page') || '1');
    const safePage = Number.isFinite(pageValue) && pageValue > 0 ? pageValue : 1;
    if (assignedViewMode) {
        paginationState.assigned = safePage;
    } else if (window.managementView) {
        paginationState.management = safePage;
    }
    if (mgmtStatusFilter && params.has('status')) mgmtStatusFilter.value = params.get('status') || '';
    if (mgmtTypeFilter && params.has('hiccup_type')) mgmtTypeFilter.value = params.get('hiccup_type') || '';
    if (mgmtRootFilter && params.has('root_cause_category')) mgmtRootFilter.value = params.get('root_cause_category') || '';
    if (mgmtDateFromFilter && params.has('date_from')) mgmtDateFromFilter.value = params.get('date_from') || '';
    if (mgmtDateToFilter && params.has('date_to')) mgmtDateToFilter.value = params.get('date_to') || '';
    if (mgmtEscalatedFilter) mgmtEscalatedFilter.checked = parseBooleanParam(params.get('escalated') || '');
    if (mgmtOverdueFilter) mgmtOverdueFilter.checked = parseBooleanParam(params.get('overdue') || '');
    if (mgmtGlobalSearchInput && params.has('search')) mgmtGlobalSearchInput.value = params.get('search') || '';
}

function buildManagementPageUrl(page) {
    const params = buildManagementFilters(page);
    params.delete('_ts');
    return `${window.location.pathname}?${params.toString()}`;
}

function syncManagementPageUrl(page) {
    if (!(window.managementView || assignedViewMode) || !window.history?.replaceState) {
        return;
    }
    const nextUrl = buildManagementPageUrl(page);
    window.history.replaceState({ page }, '', nextUrl);
}

function getUrlPageParam(fallback = 1) {
    const params = new URLSearchParams(window.location.search);
    const raw = Number(params.get('page') || '');
    return Number.isFinite(raw) && raw > 0 ? raw : fallback;
}

function buildMyFilters(page = paginationState.raised || 1) {
    const params = new URLSearchParams({
        page: String(page),
        page_size: String(hiccupPageSize),
    });
    if (statusFilter?.value) params.set('status', statusFilter.value);
    if (typeFilter?.value) params.set('hiccup_type', typeFilter.value);
    if (dateFromFilter?.value) params.set('date_from', dateFromFilter.value);
    if (dateToFilter?.value) params.set('date_to', dateToFilter.value);
    if (escalatedFilter?.checked) params.set('escalated', 'true');
    if (overdueFilter?.checked) params.set('overdue', 'true');
    if (responseBlockedFilter?.checked) {
        params.set('status', 'Open');
        params.set('response_blocked', 'true');
    }
    const searchValue = globalSearchInput?.value?.trim();
    if (searchValue) params.set('search', searchValue);
    return params;
}

function buildManagementFilters(page = paginationState.management || 1) {
    const pageKey = assignedViewMode ? paginationState.assigned || 1 : page;
    const params = new URLSearchParams({
        page: String(pageKey),
        page_size: String(hiccupPageSize),
    });
    if (mgmtStatusFilter?.value) params.set('status', mgmtStatusFilter.value);
    if (mgmtTypeFilter?.value) params.set('hiccup_type', mgmtTypeFilter.value);
    if (mgmtRootFilter?.value) params.set('root_cause_category', mgmtRootFilter.value);
    if (mgmtDateFromFilter?.value) params.set('date_from', mgmtDateFromFilter.value);
    if (mgmtDateToFilter?.value) params.set('date_to', mgmtDateToFilter.value);
    if (mgmtEscalatedFilter?.checked) params.set('escalated', 'true');
    if (mgmtOverdueFilter?.checked) params.set('overdue', 'true');
    if (mgmtResponseBlockedFilter?.checked) {
        params.set('status', 'Open');
        params.set('response_blocked', 'true');
    }
    const searchValue = mgmtGlobalSearchInput?.value?.trim();
    if (searchValue) params.set('search', searchValue);
    return params;
}

async function fetchHiccupList(endpoint, params) {
    const requestParams = params instanceof URLSearchParams ? new URLSearchParams(params) : new URLSearchParams();
    const responseBlockedRequested = requestParams.get('response_blocked') === 'true';
    requestParams.set('_ts', String(Date.now()));
    const query = `?${requestParams.toString()}`;
    const payload = await fetchJSON(`${endpoint}${query}`);
    let items = Array.isArray(payload)
        ? payload
        : Array.isArray(payload?.items)
        ? payload.items
        : [];
    if (responseBlockedRequested && items.some((entry) => Object.prototype.hasOwnProperty.call(entry || {}, 'response_blocked'))) {
        items = items.filter((entry) => entry?.status === 'Open' && Boolean(entry?.response_blocked));
    }
    const page = payload?.page || 1;
    const pageSize = payload?.page_size || hiccupPageSize;
    const total = Array.isArray(payload) ? items.length : payload?.total || 0;
    const totalPages = Array.isArray(payload)
        ? Math.max(Math.ceil(total / pageSize), 1)
        : payload?.total_pages || 1;
    await hydrateRaisedAgainstNames(items);
    return {
        items,
        page,
        page_size: pageSize,
        total,
        total_pages: totalPages,
        start: items.length ? (page - 1) * pageSize + 1 : 0,
        end: items.length ? (page - 1) * pageSize + items.length : 0,
    };
}

function syncVisibleRows() {
    const visibleRows = [
        ...(raisedListState.items || []),
        ...(assignedListState.items || []),
        ...(managementListState.items || []),
    ];
    const unique = new Map();
    visibleRows.forEach((row) => {
        if (row?.hiccup_id) {
            unique.set(row.hiccup_id, row);
        }
    });
    myHiccupsData = Array.from(unique.values());
}

function closeFilterDrawer(drawerId = null) {
    const selector = drawerId
        ? `[data-filter-drawer="${drawerId}"]`
        : '.hiccup-filter-drawer.is-open';
    const drawers = Array.from(document.querySelectorAll(selector));
    drawers.forEach((drawer) => {
        drawer.classList.remove('is-open');
        drawer.setAttribute('aria-hidden', 'true');
    });
    activeFilterDrawerId = null;
    document.body.classList.remove('hiccup-filter-drawer-open');
}

function openFilterDrawer(drawerId) {
    if (!drawerId) return;
    const drawer = document.querySelector(`[data-filter-drawer="${drawerId}"]`);
    if (!drawer) return;
    closeFilterDrawer();
    drawer.classList.add('is-open');
    drawer.setAttribute('aria-hidden', 'false');
    activeFilterDrawerId = drawerId;
    document.body.classList.add('hiccup-filter-drawer-open');
}

function renderActiveFilterChips(containerId, chips, scope) {
    const container = document.getElementById(containerId);
    if (!container) return;
    if (!chips.length) {
        container.innerHTML = '';
        return;
    }
    const chipHtml = chips
        .map(
            (chip) => `
                <button type="button" class="hiccup-active-filter-chip" data-filter-chip-clear="${scope}:${chip.key}">
                    <span>${escapeHtml(chip.label)}</span>
                    <strong>&times;</strong>
                </button>
            `
        )
        .join('');
    container.innerHTML = `
        <div class="hiccup-active-filter-row">
            ${chipHtml}
            <button type="button" class="hiccup-active-filter-clearall" data-filter-chip-clear="${scope}:all">Clear all</button>
        </div>
    `;
}

function renderMyActiveFilters() {
    const chips = [];
    const statusValue = statusFilter?.value?.trim();
    const typeValue = typeFilter?.value?.trim();
    const fromValue = dateFromFilter?.value?.trim();
    const toValue = dateToFilter?.value?.trim();
    const searchValue = globalSearchInput?.value?.trim();
    if (statusValue) chips.push({ key: 'status', label: `Status: ${statusValue}` });
    if (typeValue) chips.push({ key: 'type', label: `Type: ${typeValue}` });
    if (fromValue) chips.push({ key: 'from', label: `From: ${fromValue}` });
    if (toValue) chips.push({ key: 'to', label: `To: ${toValue}` });
    if (escalatedFilter?.checked) chips.push({ key: 'escalated', label: 'Escalated' });
    if (overdueFilter?.checked) chips.push({ key: 'overdue', label: 'Overdue' });
    if (responseBlockedFilter?.checked) chips.push({ key: 'response_blocked', label: 'Response Blocked' });
    if (searchValue) chips.push({ key: 'search', label: `Search: ${searchValue}` });
    renderActiveFilterChips('my-active-filters', chips, 'my');
}

function renderMgmtActiveFilters() {
    const chips = [];
    const statusValue = mgmtStatusFilter?.value?.trim();
    const typeValue = mgmtTypeFilter?.value?.trim();
    const rootValue = mgmtRootFilter?.value?.trim();
    const fromValue = mgmtDateFromFilter?.value?.trim();
    const toValue = mgmtDateToFilter?.value?.trim();
    const searchValue = mgmtGlobalSearchInput?.value?.trim();
    if (statusValue) chips.push({ key: 'status', label: `Status: ${statusValue}` });
    if (typeValue) chips.push({ key: 'type', label: `Type: ${typeValue}` });
    if (rootValue) chips.push({ key: 'root', label: `Cause: ${rootValue}` });
    if (fromValue) chips.push({ key: 'from', label: `From: ${fromValue}` });
    if (toValue) chips.push({ key: 'to', label: `To: ${toValue}` });
    if (mgmtEscalatedFilter?.checked) chips.push({ key: 'escalated', label: 'Escalated' });
    if (mgmtOverdueFilter?.checked) chips.push({ key: 'overdue', label: 'Overdue' });
    if (mgmtResponseBlockedFilter?.checked) chips.push({ key: 'response_blocked', label: 'Response Blocked' });
    if (searchValue) chips.push({ key: 'search', label: `Search: ${searchValue}` });
    renderActiveFilterChips('mgmt-active-filters', chips, 'mgmt');
}

function clearMyFilterChip(key) {
    if (key === 'all') {
        if (statusFilter) statusFilter.value = '';
        if (typeFilter) typeFilter.value = '';
        if (dateFromFilter) dateFromFilter.value = '';
        if (dateToFilter) dateToFilter.value = '';
        if (escalatedFilter) escalatedFilter.checked = false;
        if (overdueFilter) overdueFilter.checked = false;
        if (responseBlockedFilter) responseBlockedFilter.checked = false;
        if (globalSearchInput) globalSearchInput.value = '';
    } else if (key === 'status' && statusFilter) statusFilter.value = '';
    else if (key === 'type' && typeFilter) typeFilter.value = '';
    else if (key === 'from' && dateFromFilter) dateFromFilter.value = '';
    else if (key === 'to' && dateToFilter) dateToFilter.value = '';
    else if (key === 'escalated' && escalatedFilter) escalatedFilter.checked = false;
    else if (key === 'overdue' && overdueFilter) overdueFilter.checked = false;
    else if (key === 'response_blocked' && responseBlockedFilter) responseBlockedFilter.checked = false;
    else if (key === 'search' && globalSearchInput) globalSearchInput.value = '';
    paginationState.raised = 1;
    paginationState.against = 1;
    loadMyHiccups();
}

function clearMgmtFilterChip(key) {
    if (key === 'all') {
        if (mgmtStatusFilter) mgmtStatusFilter.value = '';
        if (mgmtTypeFilter) mgmtTypeFilter.value = '';
        if (mgmtRootFilter) mgmtRootFilter.value = '';
        if (mgmtDateFromFilter) mgmtDateFromFilter.value = '';
        if (mgmtDateToFilter) mgmtDateToFilter.value = '';
        if (mgmtEscalatedFilter) mgmtEscalatedFilter.checked = false;
        if (mgmtOverdueFilter) mgmtOverdueFilter.checked = false;
        if (mgmtResponseBlockedFilter) mgmtResponseBlockedFilter.checked = false;
        if (mgmtGlobalSearchInput) mgmtGlobalSearchInput.value = '';
    } else if (key === 'status' && mgmtStatusFilter) mgmtStatusFilter.value = '';
    else if (key === 'type' && mgmtTypeFilter) mgmtTypeFilter.value = '';
    else if (key === 'root' && mgmtRootFilter) mgmtRootFilter.value = '';
    else if (key === 'from' && mgmtDateFromFilter) mgmtDateFromFilter.value = '';
    else if (key === 'to' && mgmtDateToFilter) mgmtDateToFilter.value = '';
    else if (key === 'escalated' && mgmtEscalatedFilter) mgmtEscalatedFilter.checked = false;
    else if (key === 'overdue' && mgmtOverdueFilter) mgmtOverdueFilter.checked = false;
    else if (key === 'response_blocked' && mgmtResponseBlockedFilter) mgmtResponseBlockedFilter.checked = false;
    else if (key === 'search' && mgmtGlobalSearchInput) mgmtGlobalSearchInput.value = '';
    if (assignedViewMode) {
        paginationState.assigned = 1;
    } else {
        paginationState.management = 1;
    }
    loadMyHiccups();
}

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

function isEscalated(entry) {
    return (
        entry.status === 'Escalated to NC' ||
        Boolean(entry.escalated_by) ||
        Boolean(entry.nc_assigned_staff_id)
    );
}

function isOverdue(entry) {
    return Boolean(entry.is_response_overdue || entry.was_response_overdue || entry.is_closure_overdue);
}

function inDateRange(createdAt, fromValue, toValue) {
    if (!createdAt) return true;
    const createdDate = new Date(createdAt);
    if (Number.isNaN(createdDate.getTime())) return true;
    if (fromValue) {
        const fromDate = new Date(`${fromValue}T00:00:00`);
        if (createdDate < fromDate) return false;
    }
    if (toValue) {
        const toDate = new Date(`${toValue}T23:59:59`);
        if (createdDate > toDate) return false;
    }
    return true;
}

function paginateRows(rows, stateKey) {
    const total = rows.length;
    if (!total) {
        paginationState[stateKey] = 1;
        return {
            pagedRows: [],
            meta: {
                page: 1,
                totalPages: 1,
                total,
                start: 0,
                end: 0,
            },
        };
    }
    const totalPages = Math.max(Math.ceil(total / hiccupPageSize), 1);
    const currentPage = Math.min(Math.max(paginationState[stateKey] || 1, 1), totalPages);
    paginationState[stateKey] = currentPage;
    const startIndex = (currentPage - 1) * hiccupPageSize;
    const endIndex = Math.min(startIndex + hiccupPageSize, total);
    return {
        pagedRows: rows.slice(startIndex, endIndex),
        meta: {
            page: currentPage,
            totalPages,
            total,
            start: startIndex + 1,
            end: endIndex,
        },
    };
}

function renderPagination(containerId, stateKey, meta, label = 'hiccups') {
    const container = document.getElementById(containerId);
    if (!container) return;
    const hasRows = meta.total > 0;
    if (!hasRows) {
        container.innerHTML = '';
        return;
    }
    const totalPages = meta.totalPages || meta.total_pages || 1;
    const disablePrev = meta.page <= 1;
    const disableNext = meta.page >= totalPages;
    const prevPage = Math.max((meta.page || 1) - 1, 1);
    const nextPage = Math.min((meta.page || 1) + 1, totalPages);
    const prevControl = `<button
            type="button"
            class="hiccup-pagination-btn"
            data-pagination-action="prev"
            data-pagination-target="${stateKey}"
            data-pagination-page="${prevPage}"
            ${disablePrev ? 'disabled' : ''}
        >
            Previous
        </button>`;
    const nextControl = `<button
            type="button"
            class="hiccup-pagination-btn"
            data-pagination-action="next"
            data-pagination-target="${stateKey}"
            data-pagination-page="${nextPage}"
            ${disableNext ? 'disabled' : ''}
        >
            Next
        </button>`;
    container.innerHTML = `
        <div class="hiccup-pagination-controls">
            <p class="hiccup-pagination-summary">
                Showing ${meta.start}-${meta.end} of ${meta.total} ${label}
            </p>
            <div class="hiccup-pagination-actions">
                <label class="hiccup-page-size">
                    <span>Rows</span>
                    <select data-page-size-target="${stateKey}">
                        ${PAGE_SIZE_OPTIONS.map((size) => `<option value="${size}" ${size === hiccupPageSize ? 'selected' : ''}>${size}</option>`).join('')}
                    </select>
                </label>
                ${prevControl}
                <span class="hiccup-pagination-page">Page ${meta.page} of ${totalPages}</span>
                ${nextControl}
            </div>
        </div>
    `;
}

function isBulkClosable(hiccup) {
    return Boolean(hiccup && hiccup.status !== 'Closed');
}

function pruneBulkCloseSelection(rows = []) {
    const closableIds = new Set(
        rows.filter(isBulkClosable).map((entry) => String(entry.hiccup_id))
    );
    Array.from(selectedBulkCloseIds).forEach((id) => {
        if (!closableIds.has(id)) {
            selectedBulkCloseIds.delete(id);
        }
    });
}

function renderBulkCloseBar(rows = []) {
    if (!bulkCloseEnabled) {
        return;
    }
    const bar = document.getElementById('bulk-close-bar');
    const countEl = document.getElementById('bulk-close-count');
    const button = document.getElementById('bulk-close-action');
    const selectAll = document.getElementById('bulk-close-select-all');
    const selectedCount = selectedBulkCloseIds.size;
    const closableRows = rows.filter(isBulkClosable);

    if (countEl) {
        countEl.textContent = selectedCount
            ? `${selectedCount} selected`
            : `${closableRows.length} closable`;
    }
    if (button) {
        button.disabled = selectedCount === 0;
    }
    if (selectAll) {
        selectAll.disabled = closableRows.length === 0;
        selectAll.checked =
            closableRows.length > 0 &&
            closableRows.every((h) => selectedBulkCloseIds.has(String(h.hiccup_id)));
        selectAll.indeterminate =
            selectedCount > 0 &&
            closableRows.some((h) => selectedBulkCloseIds.has(String(h.hiccup_id))) &&
            !selectAll.checked;
    }
    bar?.classList.toggle('hidden', closableRows.length === 0);
}

function managementActionButtons(hiccup) {
    const { hiccup_id: id, status, escalated_by, nc_assigned_staff_id } = hiccup;
    const hasEscalation = Boolean(
        status === 'Escalated to NC' || escalated_by || nc_assigned_staff_id
    );
    const assignedToCurrentUser =
        nc_assigned_staff_id &&
        currentUserId &&
        String(nc_assigned_staff_id) === String(currentUserId);
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
        hasEscalation
            ? {
                  label: 'View NC Form',
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
            const readonlyAttr =
                action.behavior === 'view-nc' && (status === 'Closed' || !assignedToCurrentUser)
                    ? 'data-nc-readonly="true"'
                    : '';
            return `<button type="button" class="mgmt-pill ${action.classes}" data-hiccup="${id}" ${statusAttr} ${behaviorAttr} ${readonlyAttr}>${action.label}</button>`;
        })
        .join('');
}

function actionControlsHtml(h, includeMgmtActions = false, options = {}) {
    const {
        allowNcView = false,
        ncReadonly = false,
        allowRespond = false,
        showNcButton = false,
        detailMode = 'modal',
        isExpanded = false,
        accordionScope = '',
        includeDetail = true,
        directActions = false,
    } = options;
    const allowNcViewForCell = resolveOptionValue(allowNcView, h);
    const ncReadonlyValue = resolveOptionValue(ncReadonly, h);
    const detailButton = !includeDetail
        ? ''
        : detailMode === 'accordion'
            ? `<button type="button" data-hiccup-detail="${h.hiccup_id}" data-accordion-scope="${accordionScope}" class="detail-btn hiccup-accordion-toggle ${isExpanded ? 'is-open' : ''}" aria-expanded="${isExpanded ? 'true' : 'false'}" aria-controls="hiccup-detail-row-${accordionScope}-${escapeHtml(h.hiccup_id)}" aria-label="${isExpanded ? 'Hide' : 'Show'} details for ${escapeHtml(h.hiccup_id)}">
                <span class="hiccup-accordion-toggle__chevron">▾</span>
                <span>${isExpanded ? 'Hide details' : 'Details'}</span>
            </button>`
            : `<button type="button" data-hiccup-detail="${h.hiccup_id}" class="detail-btn" aria-label="Details for ${escapeHtml(h.hiccup_id)}">View details</button>`;
    let mgmtActions = '';
    if (includeMgmtActions) {
        const mgmtButtons = managementActionButtons(h);
        if (mgmtButtons) {
            mgmtActions = directActions
                ? `<div class="hiccup-direct-actions">${mgmtButtons}</div>`
                : `<div class="mgmt-action-group" data-hiccup-actions="${h.hiccup_id}">
                <button type="button" class="mgmt-toggle" aria-haspopup="true" aria-expanded="false">Actions</button>
                <div class="mgmt-actions-stack">
                    ${mgmtButtons}
                </div>
           </div>`;
        }
    }
    const ncViewButton =
        showNcButton && allowNcViewForCell
            ? `<button type="button" class="detail-btn" data-behavior="view-nc" data-nc-readonly="${ncReadonlyValue}" data-hiccup="${h.hiccup_id}">View NC Form</button>`
            : '';
    const respondButton =
        allowRespond && h.status !== 'Closed'
            ? `<button type="button" class="detail-btn" data-behavior="respond" data-hiccup="${h.hiccup_id}">Respond</button>`
            : '';
    return `
        <div class="hiccup-inline-actions">
            ${detailButton}
            ${mgmtActions}
            ${ncViewButton}
            ${respondButton}
        </div>`;
}

function actionCellHtml(h, includeMgmtActions = false, options = {}) {
    return `<td class="px-4 py-3 align-top">
        ${actionControlsHtml(h, includeMgmtActions, options)}
    </td>`;
}

function getActiveDetailCollection() {
    if (assignedViewMode || window.managementView) {
        return Array.isArray(managementListState.items) ? managementListState.items : [];
    }
    const againstTab = document.getElementById('tab-against-me');
    const isAgainstActive = Boolean(againstTab && againstTab.classList.contains('is-active'));
    if (isAgainstActive) {
        return Array.isArray(assignedListState.items) ? assignedListState.items : [];
    }
    return Array.isArray(raisedListState.items) ? raisedListState.items : [];
}

function buildDetailNavigation(h, collection = []) {
    const rows = Array.isArray(collection) ? collection : [];
    const currentIndex = rows.findIndex((entry) => entry?.hiccup_id === h.hiccup_id);
    if (currentIndex === -1 || rows.length <= 1) {
        return {
            markup: '',
            prevHiccup: null,
            nextHiccup: null,
        };
    }
    const prevHiccup = currentIndex > 0 ? rows[currentIndex - 1] : null;
    const nextHiccup = currentIndex < rows.length - 1 ? rows[currentIndex + 1] : null;
    const markup = `
        <div class="hiccup-detail-nav">
            <button
                type="button"
                class="detail-btn"
                data-detail-nav="prev"
                ${prevHiccup ? '' : 'disabled'}
            >
                Prev
            </button>
            <span class="hiccup-detail-nav__meta">Item ${currentIndex + 1} of ${rows.length}</span>
            <button
                type="button"
                class="detail-btn"
                data-detail-nav="next"
                ${nextHiccup ? '' : 'disabled'}
            >
                Next
            </button>
        </div>
    `;
    return { markup, prevHiccup, nextHiccup };
}

function detailMarkup(h, ncForm, collection = [], options = {}) {
    const { includeNavigation = true, includeActions = true, inline = false, extraActionsHtml = '' } = options;
    const navigation = includeNavigation ? buildDetailNavigation(h, collection) : { markup: '' };
    const peopleCards = [
        { title: 'Raised By', value: formatPersonDisplay(h.raised_by_name) },
        { title: 'Raised Against', value: formatPersonDisplay(h.raised_against_name) },
    ];
    const contextCards = [
        { title: 'Against Dept', value: normalizeText(h.raised_against_department_name || h.raised_against_department) },
        { title: 'Root Cause', value: normalizeText(h.root_cause_category) },
    ];
    if (ncForm?.staff_name) {
        contextCards.push({
            title: 'NC Escalated Staff',
            value: formatPersonDisplay(ncForm.staff_name),
        });
    }
    if (h.nc_assigned_staff_name) {
        contextCards.push({
            title: 'Assigned Staff',
            value: formatPersonDisplay(h.nc_assigned_staff_name),
        });
    }
    const attachmentSource =
        Array.isArray(h.attachments) && h.attachments.length ? h.attachments : h.attachment_path;
    const renderInfoItems = (cards) =>
        cards
            .map(
                ({ title, value }) => `
                    <div class="hiccup-info-item">
                        <p class="hiccup-info-item__label">${title}</p>
                        <p class="hiccup-info-item__value">${value ?? '-'}</p>
                    </div>
                `
            )
            .join('');
    const responseHtml = h.response_text
        ? `
            <div class="hiccup-detail-response">
                <p class="hiccup-detail-response__title">Response</p>
                <p class="hiccup-detail-response__text">${escapeHtml(h.response_text)}</p>
                <p class="hiccup-detail-response__meta">Responded by <span>${formatPersonDisplay(h.response_by_name, h.response_by)}</span></p>
            </div>`
        : '';
    const badges = `
        <div class="hiccup-detail-badges">
            ${formatOverdueBadges(h)}
            <span class="hiccup-detail-pill">Auto: ${h.is_auto_generated ? 'Yes' : 'No'}</span>
            <span class="hiccup-detail-pill">Confidential: ${h.confidential_flag ? 'Yes' : 'No'}</span>
        </div>
    `;
    const modalActionButtons = includeActions && showManagementActions ? managementActionButtons(h) : '';
    const modalActions = modalActionButtons
        ? `
            <div class="hiccup-detail-actionbar">
                ${modalActionButtons}
            </div>
        `
        : '';
    return `
        <div class="hiccup-detail-canvas ${inline ? 'hiccup-detail-canvas--inline' : ''}">
            <div class="hiccup-detail-modal hiccup-detail-modal--compact ${inline ? 'hiccup-detail-modal--inline' : ''}">
                <div class="hiccup-detail-head">
                    <div>
                        <div class="hiccup-detail-id">#${escapeHtml(h.hiccup_id)}</div>
                        <p class="hiccup-detail-sub">Quick incident summary</p>
                    </div>
                    ${badges}
                </div>
                ${navigation.markup}
                <div class="hiccup-detail-compact-grid">
                    <aside class="hiccup-detail-section hiccup-detail-section--people">
                        <div class="hiccup-detail-section__head">
                            <span>People</span>
                            <small>Who is involved</small>
                        </div>
                        <div class="hiccup-info-list">
                            ${renderInfoItems(peopleCards)}
                        </div>
                    </aside>
                    <main class="hiccup-detail-section hiccup-detail-section--issue">
                        <div class="hiccup-detail-section__head">
                            <span>Issue</span>
                            <small>What happened</small>
                        </div>
                        <div class="hiccup-issue-grid">
                            <div class="hiccup-detail-panel">
                                <p class="hiccup-detail-panel__title">Description</p>
                                <div class="hiccup-detail-panel__body hiccup-detail-panel__body--lg">${escapeHtml(h.description || '-')}</div>
                            </div>
                            <div class="hiccup-detail-panel">
                                <p class="hiccup-detail-panel__title">Immediate Effect</p>
                                <div class="hiccup-detail-panel__body hiccup-detail-panel__body--lg">${escapeHtml(h.immediate_effect || '-')}</div>
                            </div>
                            ${
                                h.status === 'Closed' && h.closure_notes
                                    ? `<div class="hiccup-detail-panel hiccup-detail-panel--success hiccup-detail-panel--wide">
                                        <p class="hiccup-detail-panel__title">Closure Notes</p>
                                        <p class="hiccup-detail-panel__body">${truncatedText(h.closure_notes, 260)}</p>
                                       </div>`
                                    : ''
                            }
                        </div>
                        ${responseHtml}
                    </main>
                    <aside class="hiccup-detail-section hiccup-detail-section--context">
                        <div class="hiccup-detail-section__head">
                            <span>Context</span>
                            <small>Useful details</small>
                        </div>
                        <div class="hiccup-info-list">
                            ${renderInfoItems(contextCards)}
                        </div>
                        <div class="hiccup-detail-panel hiccup-detail-panel--flat hiccup-context-attachments">
                            <p class="hiccup-detail-panel__title">Attachments</p>
                            <div class="hiccup-detail-panel__body attachment-stack">
                                ${formatAttachment(attachmentSource)}
                            </div>
                        </div>
                    </aside>
                    ${
                        modalActions || extraActionsHtml
                            ? `<section class="hiccup-detail-section hiccup-detail-section--actions">
                                <div class="hiccup-detail-section__head">
                                    <span>Actions</span>
                                    <small>Next steps</small>
                                </div>
                                ${modalActions}
                                ${extraActionsHtml ? `<div class="hiccup-detail-actionbar">${extraActionsHtml}</div>` : ''}
                               </section>`
                            : ''
                    }
                </div>
            </div>
        </div>
    `;
}

function closeOverlayModals() {
    const ncSummaryModal = document.getElementById('nc-view-modal');
    if (ncSummaryModal) {
        ncSummaryModal.remove();
    }
    if (typeof Swal !== 'undefined' && Swal.isVisible()) {
        Swal.close();
    }
}

async function fetchNCEscalationForm(hiccupId) {
    try {
        return await fetchJSON(`/api/hiccups/${hiccupId}/nc-form`);
    } catch (err) {
        console.error('Unable to load NC escalation form', err);
        return null;
    }
}

async function presentHiccupDetails(h, collection = getActiveDetailCollection()) {
    closeOverlayModals();
    let ncForm = null;
    if (h.status === 'Escalated to NC') {
        ncForm = await fetchNCEscalationForm(h.hiccup_id);
    }
    const navigation = buildDetailNavigation(h, collection);
    Swal.fire({
        title: '',
        html: detailMarkup(h, ncForm, collection),
        width: 1120,
        heightAuto: false,
        showCloseButton: false,
        allowEscapeKey: true,
        confirmButtonText: 'Close (Press ESC key)',
        background: '#f8fafc',
        customClass: {
            container: 'swal-detail-container',
            popup: 'swal-detail-popup',
            htmlContainer: 'swal-detail-html',
        },
        didOpen: () => {
            const popup = Swal.getPopup();
            if (!popup) {
                return;
            }
            const prevBtn = popup.querySelector('[data-detail-nav="prev"]');
            const nextBtn = popup.querySelector('[data-detail-nav="next"]');
            prevBtn?.addEventListener('click', () => {
                if (navigation.prevHiccup) {
                    presentHiccupDetails(navigation.prevHiccup, collection);
                }
            });
            nextBtn?.addEventListener('click', () => {
                if (navigation.nextHiccup) {
                    presentHiccupDetails(navigation.nextHiccup, collection);
                }
            });
        },
    });
}

function summaryRowHtml(h, includeActions = true, includeMgmtActions = false, options = {}) {
    const {
        displayRaisedAgainst = true,
        allowNcView = false,
        ncReadonly = false,
        allowRespond = false,
        showNcButton = false,
        inlineDetails = false,
        accordionScope = 'management',
        includeBulkSelect = false,
    } = options;
    const isExpanded = inlineDetails && getExpandedHiccupId(accordionScope) === h.hiccup_id;
    const inlineActionControls = includeActions
        ? actionControlsHtml(h, includeMgmtActions, {
              allowNcView,
              ncReadonly,
              allowRespond,
              showNcButton,
              detailMode: inlineDetails ? 'accordion' : 'modal',
              isExpanded,
              accordionScope,
              includeDetail: false,
              directActions: true,
          })
        : '';
    const targetPerson = displayRaisedAgainst
        ? formatPersonDisplay(h.raised_against_name, h.raised_against)
        : formatPersonDisplay(h.raised_by_name, h.raised_by);
    const detailCellColspan = inlineDetails && includeBulkSelect ? managementColumnCount : listColumnCount;
    const bulkSelectCell =
        includeBulkSelect && bulkCloseEnabled
            ? `<td class="hiccup-select-col px-2 py-3 align-top">
                <input
                    type="checkbox"
                    class="hiccup-bulk-checkbox"
                    data-bulk-close-id="${escapeHtml(h.hiccup_id)}"
                    ${selectedBulkCloseIds.has(String(h.hiccup_id)) ? 'checked' : ''}
                    ${isBulkClosable(h) ? '' : 'disabled'}
                    aria-label="Select ${escapeHtml(h.hiccup_id)} for bulk close"
                >
            </td>`
            : '';
    const detailRow = isExpanded
        ? `<tr id="hiccup-detail-row-${accordionScope}-${escapeHtml(h.hiccup_id)}" class="hiccup-accordion-row">
            <td colspan="${detailCellColspan}" class="hiccup-accordion-cell">
                ${detailMarkup(h, null, [], {
                    includeNavigation: false,
                    includeActions: false,
                    inline: true,
                    extraActionsHtml: inlineActionControls,
                })}
            </td>
        </tr>`
        : '';
    const idButtonClass = inlineDetails
        ? `font-semibold text-tealbrand detail-btn hiccup-row-toggle ${isExpanded ? 'is-open' : ''}`
        : 'font-semibold text-tealbrand detail-btn';
    const idButtonAttrs = inlineDetails
        ? `data-accordion-scope="${accordionScope}" aria-expanded="${isExpanded ? 'true' : 'false'}" aria-controls="hiccup-detail-row-${accordionScope}-${escapeHtml(h.hiccup_id)}"`
        : '';
    return `<tr class="border-b border-slate-100 hover:bg-white ${isExpanded ? 'hiccup-summary-row--open' : ''}">
        ${bulkSelectCell}
        <td class="px-4 py-3 align-top">
            <button type="button" data-hiccup-detail="${h.hiccup_id}" class="${idButtonClass}" ${idButtonAttrs}>
                ${inlineDetails ? `<span class="hiccup-accordion-toggle__chevron">▾</span>` : ''}
                <span>${escapeHtml(h.hiccup_id)}</span>
            </button>
        </td>
        <td class="px-4 py-3 align-top">${normalizeText(h.hiccup_type)}</td>
        <td class="px-4 py-3 align-top">${statusWithBadges(h)}</td>
        <td class="px-4 py-3 align-top">${targetPerson}</td>
        <td class="px-4 py-3 align-top">${formatDate(h.created_at)}</td>
    </tr>${detailRow}`;
}

function getExpandedHiccupId(scope) {
    return expandedHiccupByScope[scope] || null;
}

function toggleHiccupAccordion(scope, hiccupId) {
    if (!scope || !Object.prototype.hasOwnProperty.call(expandedHiccupByScope, scope)) {
        return;
    }
    expandedHiccupByScope[scope] = expandedHiccupByScope[scope] === hiccupId ? null : hiccupId;
    document.querySelectorAll('.mgmt-action-group.open').forEach((group) => {
        group.classList.remove('open');
        group.querySelector('.mgmt-toggle')?.setAttribute('aria-expanded', 'false');
    });
    renderAllTables();
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
        showNcButton = false,
        inlineDetails = false,
        accordionScope = 'raised',
    } = options;
    const isExpanded = inlineDetails && getExpandedHiccupId(accordionScope) === h.hiccup_id;
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
    const ncReadonlyValue = resolveOptionValue(ncReadonly, h);
    const ncViewButton =
        showNcButton && allowNcViewForCard
            ? `<button type="button" class="detail-btn" data-behavior="view-nc" data-nc-readonly="${ncReadonlyValue}" data-hiccup="${h.hiccup_id}">View NC Form</button>`
            : '';
    const respondButton =
        allowRespondForCard && h.status !== 'Closed'
            ? `<button type="button" class="detail-btn" data-behavior="respond" data-hiccup="${h.hiccup_id}">Respond</button>`
            : '';
    const detailButton = inlineDetails
        ? `<button type="button" data-hiccup-detail="${h.hiccup_id}" data-accordion-scope="${accordionScope}" class="detail-btn hiccup-accordion-toggle ${isExpanded ? 'is-open' : ''}" aria-expanded="${isExpanded ? 'true' : 'false'}" aria-controls="hiccup-card-detail-${accordionScope}-${escapeHtml(h.hiccup_id)}">
            <span class="hiccup-accordion-toggle__chevron">⌄</span>
            <span>${isExpanded ? 'Hide details' : 'Details'}</span>
        </button>`
        : `<button type="button" data-hiccup-detail="${h.hiccup_id}" class="detail-btn">View details</button>`;
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
            ${
                isExpanded
                    ? `<div id="hiccup-card-detail-${accordionScope}-${escapeHtml(h.hiccup_id)}" class="hiccup-card-accordion">
                        ${detailMarkup(h, null, [], {
                            includeNavigation: false,
                            includeActions: false,
                            inline: true,
                        })}
                    </div>`
                    : ''
            }
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
    const filtered = Array.isArray(raisedListState.items) ? raisedListState.items : [];
    const visibleRows = filtered;
    const allowNcForCreator = (h) =>
        h.status === 'Escalated to NC' || h.escalated_by || h.nc_assigned_staff_id;
    renderMyActiveFilters();
    renderHiccupCards('raised-by-cards', visibleRows, {
        displayRaisedAgainst: true,
        allowNcView: allowNcForCreator,
        ncReadonly: true,
        showNcButton: true,
        inlineDetails: true,
        accordionScope: 'raised',
    });
    renderPagination('pagination-raised', 'raised', raisedListState);
    if (tbody) {
        if (filtered.length === 0) {
            tbody.innerHTML = `<tr><td colspan="${listColumnCount}" class="px-4 py-4 text-center text-xs uppercase tracking-[0.3em] text-slate-400">No hiccups yet.</td></tr>`;
        } else {
            tbody.innerHTML = visibleRows
                .map((h) =>
                    summaryRowHtml(h, true, false, {
                        allowNcView: allowNcForCreator(h),
                        ncReadonly: true,
                        showNcButton: true,
                        inlineDetails: true,
                        accordionScope: 'raised',
                    })
                )
                .join('');
        }
    }
}

function renderAssignedTable() {
    const assignedBody = document.querySelector('#assigned-table tbody');
    const assignedCardsId = 'against-me-cards';
    if (!assignedBody && !document.getElementById(assignedCardsId)) return;
    const filteredAssigned = Array.isArray(assignedListState.items) ? assignedListState.items : [];
    const visibleRows = filteredAssigned;
    if (assignedListState.total === 0) {
        if (assignedBody) {
            assignedBody.innerHTML = `<tr><td colspan="${listColumnCount}" class="px-4 py-4 text-center text-xs uppercase tracking-[0.3em] text-slate-400">No assignments yet.</td></tr>`;
        }
        renderHiccupCards(assignedCardsId, [], {
            displayRaisedAgainst: false,
        });
        renderPagination('pagination-against', 'against', assignedListState, 'assignments');
        return;
    }
    if (filteredAssigned.length === 0) {
        if (assignedBody) {
            assignedBody.innerHTML = `<tr><td colspan="${listColumnCount}" class="px-4 py-4 text-center text-xs uppercase tracking-[0.3em] text-slate-400">No assignments yet.</td></tr>`;
        }
        renderHiccupCards(assignedCardsId, [], {
            displayRaisedAgainst: false,
        });
        renderPagination('pagination-against', 'against', assignedListState, 'assignments');
        return;
    }
    const isAssignedNc = (entry) =>
        entry &&
        entry.nc_assigned_staff_id &&
        currentUserId &&
        String(entry.nc_assigned_staff_id) === String(currentUserId);
    const ncReadonlyForAssigned = (h) => h.status === 'Closed';
    renderHiccupCards(assignedCardsId, visibleRows, {
        displayRaisedAgainst: false,
        allowRespond: (h) => h.status !== 'Closed' && !h.response_text,
        allowNcView: (h) =>
            isAssignedNc(h) && (h.status === 'Escalated to NC' || h.status === 'Closed' || h.escalated_by),
        ncReadonly: ncReadonlyForAssigned, // editable when open, read-only when closed
        showNcButton: true,
        inlineDetails: true,
        accordionScope: 'against',
    });
    renderPagination('pagination-against', 'against', assignedListState, 'assignments');
    if (assignedBody) {
        assignedBody.innerHTML = visibleRows
            .map((h) => {
                const canRespond = h.status !== 'Closed' && !h.response_text;
                return summaryRowHtml(h, true, false, {
                    displayRaisedAgainst: false,
                    allowNcView: isAssignedNc(h) && (h.status === 'Escalated to NC' || h.status === 'Closed' || h.escalated_by),
                    ncReadonly: ncReadonlyForAssigned,
                    allowRespond: canRespond,
                    showNcButton: true,
                    inlineDetails: true,
                    accordionScope: 'against',
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
    const fromValue = mgmtDateFromFilter?.value;
    const toValue = mgmtDateToFilter?.value;
    if (fromValue || toValue) {
        filtered = filtered.filter((entry) => inDateRange(entry.created_at, fromValue, toValue));
    }
    if (mgmtEscalatedFilter?.checked) {
        filtered = filtered.filter((entry) => isEscalated(entry));
    }
    if (mgmtOverdueFilter?.checked) {
        filtered = filtered.filter((entry) => isOverdue(entry));
    }
    return filtered;
}

function renderManagementTable() {
    const mgmtBody = document.querySelector('#management-table tbody');
    const mgmtCardsId = assignedViewMode ? 'assigned-nc-cards' : 'management-cards';
    if (!mgmtBody && !document.getElementById(mgmtCardsId)) return;
    const finalFiltered = Array.isArray(managementListState.items) ? managementListState.items : [];
    const visibleRows = finalFiltered;
    renderMgmtActiveFilters();
    pruneBulkCloseSelection(visibleRows);
    renderBulkCloseBar(visibleRows);
    const paginationKey = assignedViewMode ? 'assigned' : 'management';
    const paginationContainerId = assignedViewMode ? 'pagination-assigned' : 'pagination-management';
    const isAssignedNc = (entry) =>
        entry &&
        entry.nc_assigned_staff_id &&
        currentUserId &&
        String(entry.nc_assigned_staff_id) === String(currentUserId);
    const allowNcViewFn = (h) =>
        h.status === 'Escalated to NC' || h.escalated_by || h.status === 'Closed';
    const ncReadonlyFor = (h) => {
        if (h.status === 'Closed') return true;
        return !isAssignedNc(h);
    };
    renderHiccupCards(mgmtCardsId, visibleRows, {
        displayRaisedAgainst: true,
        includeMgmtActions: showManagementActions,
        allowNcView: allowNcViewFn,
        ncReadonly: ncReadonlyFor,
        showNcButton: true,
        inlineDetails: true,
        accordionScope: assignedViewMode ? 'assigned' : 'management',
    });
    renderPagination(paginationContainerId, paginationKey, managementListState);
    if (managementListState.total === 0 || finalFiltered.length === 0) {
        mgmtBody.innerHTML = `<tr><td colspan="${managementColumnCount}" class="px-4 py-4 text-center text-xs uppercase tracking-[0.3em] text-slate-400">No hiccups yet.</td></tr>`;
        return;
    }
    mgmtBody.innerHTML = visibleRows
        .map((h) =>
            summaryRowHtml(h, showManagementActions, showManagementActions, {
                allowNcView: allowNcViewFn(h),
                ncReadonly: ncReadonlyFor(h),
                inlineDetails: true,
                accordionScope: assignedViewMode ? 'assigned' : 'management',
                includeBulkSelect: true,
            })
        )
        .join('');
}

function renderAllTables() {
    syncVisibleRows();
    renderMyHiccupsTable();
    if (!assignedViewMode) {
        renderAssignedTable();
    }
    renderManagementTable();
}

resetFilters?.addEventListener('click', () => {
    if (statusFilter) statusFilter.value = '';
    if (typeFilter) typeFilter.value = '';
    if (dateFromFilter) dateFromFilter.value = '';
    if (dateToFilter) dateToFilter.value = '';
    if (escalatedFilter) escalatedFilter.checked = false;
    if (overdueFilter) overdueFilter.checked = false;
    if (responseBlockedFilter) responseBlockedFilter.checked = false;
    if (globalSearchInput) globalSearchInput.value = '';
    paginationState.raised = 1;
    paginationState.against = 1;
    loadMyHiccups();
    closeFilterDrawer();
});

mgmtResetFilters?.addEventListener('click', () => {
    if (mgmtStatusFilter) mgmtStatusFilter.value = '';
    if (mgmtTypeFilter) mgmtTypeFilter.value = '';
    if (mgmtRootFilter) mgmtRootFilter.value = '';
    if (mgmtDateFromFilter) mgmtDateFromFilter.value = '';
    if (mgmtDateToFilter) mgmtDateToFilter.value = '';
    if (mgmtEscalatedFilter) mgmtEscalatedFilter.checked = false;
    if (mgmtOverdueFilter) mgmtOverdueFilter.checked = false;
    if (mgmtResponseBlockedFilter) mgmtResponseBlockedFilter.checked = false;
    if (mgmtGlobalSearchInput) mgmtGlobalSearchInput.value = '';
    if (assignedViewMode) {
        paginationState.assigned = 1;
    } else {
        paginationState.management = 1;
    }
    loadMyHiccups();
    closeFilterDrawer();
});

function toggleHiccupTab(target) {
    const raisedSection = document.getElementById('raised-by-section');
    const againstSection = document.getElementById('against-me-section');
    const raisedCards = document.getElementById('raised-by-cards');
    const againstCards = document.getElementById('against-me-cards');
    const raisedPagination = document.getElementById('pagination-raised');
    const againstPagination = document.getElementById('pagination-against');
    const raisedTab = document.getElementById('tab-raised-by');
    const againstTab = document.getElementById('tab-against-me');
    const isRaised = target === 'raised';
    if (raisedSection) raisedSection.classList.toggle('hidden', !isRaised);
    if (againstSection) againstSection.classList.toggle('hidden', isRaised);
    if (raisedCards) raisedCards.classList.toggle('hidden', !isRaised);
    if (againstCards) againstCards.classList.toggle('hidden', isRaised);
    if (raisedPagination) raisedPagination.classList.toggle('hidden', !isRaised);
    if (againstPagination) againstPagination.classList.toggle('hidden', isRaised);
    const updateTabStyles = (tabEl, active) => {
        if (!tabEl) return;
        tabEl.classList.toggle('is-active', active);
        tabEl.setAttribute('aria-selected', active ? 'true' : 'false');
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

function setupDensityControls() {
    applyDensityMode(getSavedDensityMode());
    document.querySelectorAll('[data-density-toggle]').forEach((btn) => {
        btn.addEventListener('click', () => {
            toggleDensityMode();
        });
    });
}

async function loadMyHiccups() {
    if (!hasHiccupTables) {
        return;
    }
    const requestId = ++latestLoadRequestId;
    showLoading('Loading hiccups...');
    try {
        let nextRaisedState = defaultListState();
        let nextAssignedState = defaultListState();
        let nextManagementState = defaultListState();
        if (assignedViewMode) {
            const requestedPage = paginationState.assigned || getUrlPageParam(1);
            nextManagementState = await fetchHiccupList(
                '/api/hiccups/assigned',
                buildManagementFilters(requestedPage)
            );
        } else if (window.managementView) {
            const requestedPage = paginationState.management || getUrlPageParam(1);
            nextManagementState = await fetchHiccupList(
                '/api/hiccups/all',
                buildManagementFilters(requestedPage)
            );
        } else {
            const [raisedResult, assignedResult] = await Promise.allSettled([
                fetchHiccupList('/api/hiccups', buildMyFilters(paginationState.raised || 1)),
                fetchHiccupList('/api/hiccups/for-me', buildMyFilters(paginationState.against || 1)),
            ]);
            nextRaisedState =
                raisedResult.status === 'fulfilled'
                    ? raisedResult.value
                    : defaultListState(paginationState.raised || 1);
            nextAssignedState =
                assignedResult.status === 'fulfilled'
                    ? assignedResult.value
                    : defaultListState(paginationState.against || 1);
            if (raisedResult.status === 'rejected' && assignedResult.status === 'rejected') {
                throw (raisedResult.reason || assignedResult.reason);
            }
        }
        if (requestId !== latestLoadRequestId) {
            return;
        }
        raisedListState = nextRaisedState;
        assignedListState = nextAssignedState;
        managementListState = nextManagementState;
        if (assignedViewMode) {
            paginationState.assigned = managementListState.page || 1;
            syncManagementPageUrl(paginationState.assigned);
        } else if (window.managementView) {
            paginationState.management = managementListState.page || 1;
            syncManagementPageUrl(paginationState.management);
        }
        renderAllTables();
    } catch (err) {
        if (requestId !== latestLoadRequestId) {
            return;
        }
        console.error('Unable to load hiccups', err);
        if (err?.status === 401) {
            clearAuthState();
            window.location.href = '/login';
            return;
        }
        if (err?.status === 404 || err?.status === 204) {
            raisedListState = defaultListState();
            assignedListState = defaultListState();
            managementListState = defaultListState();
            renderAllTables();
            return;
        }
        raisedListState = defaultListState();
        assignedListState = defaultListState();
        managementListState = defaultListState();
        renderAllTables();
        await showAlert({
            icon: 'error',
            title: 'Unable to load hiccups',
            text: err?.message || 'Please refresh the page.',
        });
    } finally {
        if (requestId === latestLoadRequestId) {
            closeLoading();
        }
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
            <div class="status-modal__field-group ${field.suggestions?.listEnabled ? 'status-modal__field-group--suggestions' : ''}">
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
            ? `<div class="status-modal__suggestions" id="${field.id}-list" role="listbox"></div>`
            : '';
    const readonlyAttr = field.readonly ? 'readonly' : '';
    const disabledAttr = field.disabled ? 'disabled' : '';
    if (type === 'hidden') {
        const hiddenValue = escapeHtml(String(field.value ?? ''));
        return `<input id="${field.id}" type="hidden" value="${hiddenValue}" />`;
    }
    if (type === 'note_display') {
        const noteValue = escapeHtml(String(field.value || 'No NC note added.'));
        return `
            <div class="status-modal__note-highlight">
                <p class="status-modal__note-highlight-label">${labelText || 'NC note'}</p>
                <p class="status-modal__note-highlight-text">${noteValue}</p>
            </div>
        `;
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
                department_name: '',
                designation: item.designation || '',
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
        const suggestionBox = modal.querySelector(`#${field.id}-list`);
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
        const hideSuggestions = () => {
            if (suggestionBox) {
                suggestionBox.classList.remove('is-open');
                suggestionBox.innerHTML = '';
            }
        };
        const renderSuggestions = (list) => {
            if (!suggestionBox) {
                return;
            }
            if (!list.length) {
                suggestionBox.innerHTML = '<div class="status-modal__suggestion-empty">No active staff found</div>';
                suggestionBox.classList.add('is-open');
                return;
            }
            suggestionBox.innerHTML = list
                .map(
                    (item) => `
                        <button type="button" class="status-modal__suggestion" data-staff-id="${escapeHtml(String(item.id))}" data-staff-name="${escapeHtml(item.name)}">
                            <span class="status-modal__suggestion-name">${escapeHtml(item.name)}</span>
                            <span class="status-modal__suggestion-meta">${escapeHtml(
                                item.designation || 'Staff'
                            )}</span>
                        </button>
                    `
                )
                .join('');
            suggestionBox.classList.add('is-open');
        };
        const handler = () => {
            const value = input.value.trim();
            if (value.length < (field.suggestions.minLength ?? 2)) {
                if (suggestionBox && document.activeElement === input && value.length > 0) {
                    suggestionBox.innerHTML = '<div class="status-modal__suggestion-empty">Type at least 2 letters to search staff</div>';
                    suggestionBox.classList.add('is-open');
                } else {
                    hideSuggestions();
                }
                suggestionsCache = [];
                applyHiddenValue();
                return;
            }
            clearTimeout(timer);
            if (suggestionBox) {
                suggestionBox.innerHTML = '<div class="status-modal__suggestion-empty">Searching staff...</div>';
                suggestionBox.classList.add('is-open');
            }
            timer = setTimeout(async () => {
                const list = await fetchStaffSuggestions(value);
                suggestionsCache = list;
                renderSuggestions(list);
                applyHiddenValue();
            }, field.suggestions.debounce ?? SUGGESTION_DEBOUNCE);
        };
        const clickHandler = (event) => {
            const option = event.target.closest('.status-modal__suggestion');
            if (!option) {
                return;
            }
            input.value = option.dataset.staffName || '';
            if (hiddenInput) {
                hiddenInput.value = option.dataset.staffId || '';
            }
            hideSuggestions();
        };
        const blurHandler = () => {
            window.setTimeout(() => {
                applyHiddenValue();
                hideSuggestions();
            }, 150);
        };
        applyHiddenValue();
        input.addEventListener('input', handler);
        input.addEventListener('focus', handler);
        input.addEventListener('blur', blurHandler);
        suggestionBox?.addEventListener('click', clickHandler);
        handlers.push({ input, handler, timer, suggestionBox, clickHandler, blurHandler });
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
            suggestionHandlers.forEach(({ input, handler, timer, suggestionBox, clickHandler, blurHandler }) => {
                input.removeEventListener('input', handler);
                input.removeEventListener('focus', handler);
                input.removeEventListener('blur', blurHandler);
                if (timer) {
                    clearTimeout(timer);
                }
                if (suggestionBox) {
                    suggestionBox.removeEventListener('click', clickHandler);
                    suggestionBox.innerHTML = '';
                    suggestionBox.classList.remove('is-open');
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
                if (type === 'note_display') {
                    continue;
                }
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
    if (options.includeNcNote) {
        fields.push({
            id: 'escalation-nc-note-display',
            key: 'nc_note',
            label: 'NC note',
            type: 'note_display',
            value: initial.nc_note ?? '',
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
                    label: 'Closure notes (optional)',
                    placeholder: 'Optional - if left blank, N/A will be saved',
                    required: false,
                },
            ],
        });
    }
    if (status === 'Escalated to NC') {
        const staffResult = await showStatusModal({
            title: 'Escalate to NC – staff name',
            confirmText: 'Next',
            fields: buildStaffNameFields(),
            title: 'Escalate to NC - assign staff',
        });
        if (!staffResult) {
            return null;
        }
        const noteResult = await showStatusModal({
            title: 'NC note',
            confirmText: 'Next',
            fields: [
                {
                    id: 'escalation-nc-note',
                    key: 'nc_note',
                    label: 'NC note (optional)',
                    placeholder: 'Add a short note for this NC escalation',
                    required: false,
                    type: 'textarea',
                },
            ],
        });
        if (!noteResult) {
            return null;
        }
        const payload = {
            escalation_form: {
                staff_name: staffResult.staff_name,
                staff_id: staffResult.staff_id,
                nc_note: noteResult.nc_note,
            },
        };
        return payload;
    }
    return {};
}

function renderNCSummary(formData) {
    if (!formData) return '<p class="text-sm text-slate-600">No NC data.</p>';
    const escape = (val) => escapeHtml(val || '-');
    const list = [
        ['Staff name', formData.staff_name],
        ['NC note', formData.nc_note],
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
    closeOverlayModals();
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
#nc-view-modal .nc-view-card { position: relative; max-width: 520px; width: 92vw; max-height: 72vh; overflow: hidden; background: #fff; border-radius: 18px; box-shadow: 0 18px 38px rgba(15,23,42,0.18); padding: 16px; display: flex; flex-direction: column; }
#nc-view-modal .nc-view-header { display: flex; align-items: center; justify-content: space-between; gap: 8px; margin-bottom: 10px; }
#nc-view-modal h3 { margin: 0; font-size: 18px; font-weight: 800; color: #0f172a; }
#nc-view-modal .nc-view-close { border: none; background: #0db29c; color: #fff; border-radius: 10px; padding: 8px 12px; font-weight: 700; cursor: pointer; }
#nc-view-modal .nc-view-close:hover { background: #0a7f6f; }
#nc-view-modal .nc-view-body { max-height: 54vh; overflow-y: auto; padding-right: 4px; scrollbar-width: thin; scrollbar-color: rgba(100,116,139,0.38) transparent; }
#nc-view-modal .nc-view-footer { display: flex; justify-content: flex-end; margin-top: 12px; }
#nc-view-modal .nc-view-body::-webkit-scrollbar { width: 3px; }
#nc-view-modal .nc-view-body::-webkit-scrollbar-thumb { background: rgba(100,116,139,0.38); border-radius: 999px; }
#nc-view-modal .nc-view-body::-webkit-scrollbar-thumb:hover { background: rgba(100,116,139,0.58); }
#nc-view-modal .nc-view-body::-webkit-scrollbar-track { background: transparent; }
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
        fields: buildNCEscalationFields(formData, { includeStaffDisplay: true, includeNcNote: true }),
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
        let closurePayload = null;
        const isMgmtUser = Boolean(window.managementActionsEnabled && window.managementView);
        if (!isMgmtUser) {
            closurePayload = await showStatusModal({
                title: 'Closure notes',
                confirmText: 'Close',
                fields: [
                    {
                        id: 'closure-notes',
                        key: 'closure_notes',
                        label: 'Closure notes (optional)',
                        placeholder: 'Optional - if left blank, N/A will be saved',
                        required: false,
                        type: 'textarea',
                    },
                ],
            });
            if (!closurePayload) {
                return;
            }
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
                    closure_notes: closurePayload ? closurePayload.closure_notes : null,
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

async function bulkCloseSelectedHiccups() {
    const ids = Array.from(selectedBulkCloseIds);
    if (!ids.length) {
        return;
    }
    const choice = await confirmDialog({
        title: 'Bulk close selected hiccups?',
        text: `${ids.length} selected hiccup${ids.length > 1 ? 's' : ''} will be closed. Closure note will be saved as N/A.`,
        confirmButtonText: 'Yes, close',
        cancelButtonText: 'Cancel',
        showCancelButton: true,
    });
    if (!choice?.isConfirmed) {
        return;
    }
    showLoading('Closing selected hiccups...');
    try {
        const result = await fetchJSON('/api/hiccups/bulk/close', {
            method: 'PATCH',
            body: JSON.stringify({
                hiccup_ids: ids,
                closure_notes: 'N/A',
            }),
        });
        selectedBulkCloseIds.clear();
        await loadMyHiccups();
        const skipped = Number(result?.skipped?.length || 0);
        await showAlert({
            icon: 'success',
            title: 'Bulk close complete',
            text: skipped
                ? `${result.closed || 0} closed, ${skipped} skipped.`
                : `${result.closed || ids.length} hiccup${ids.length > 1 ? 's' : ''} closed.`,
            timer: 1400,
            showConfirmButton: false,
        });
    } catch (err) {
        await showAlert({
            icon: 'error',
            title: 'Unable to bulk close',
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
    const applyFilterButton = event.target.closest('[data-filter-apply]');
    if (applyFilterButton) {
        event.preventDefault();
        const scope = applyFilterButton.dataset.filterApply;
        if (scope === 'my') {
            paginationState.raised = 1;
            paginationState.against = 1;
        } else if (assignedViewMode) {
            paginationState.assigned = 1;
        } else {
            paginationState.management = 1;
        }
        await loadMyHiccups();
        return;
    }

    const filterChip = event.target.closest('[data-filter-chip-clear]');
    if (filterChip) {
        event.preventDefault();
        const payload = filterChip.dataset.filterChipClear || '';
        const [scope, key] = payload.split(':');
        if (scope === 'my') {
            clearMyFilterChip(key);
        } else if (scope === 'mgmt') {
            clearMgmtFilterChip(key);
        }
        return;
    }

    const filterOpenButton = event.target.closest('[data-filter-drawer-open]');
    if (filterOpenButton) {
        event.preventDefault();
        openFilterDrawer(filterOpenButton.dataset.filterDrawerOpen);
        return;
    }

    const filterCloseButton = event.target.closest('[data-filter-drawer-close]');
    if (filterCloseButton) {
        event.preventDefault();
        const parentDrawer = filterCloseButton.closest('[data-filter-drawer]');
        closeFilterDrawer(parentDrawer ? parentDrawer.dataset.filterDrawer : null);
        return;
    }

    const paginationButton = event.target.closest('[data-pagination-action]');
    if (paginationButton) {
        event.preventDefault();
        const target = paginationButton.dataset.paginationTarget;
        const requestedPage = Number(paginationButton.dataset.paginationPage || '1');
        if (target && Object.prototype.hasOwnProperty.call(paginationState, target)) {
            paginationState[target] = Math.max(requestedPage, 1);
            await loadMyHiccups();
        }
        return;
    }

    const bulkCheckbox = event.target.closest('[data-bulk-close-id]');
    if (bulkCheckbox) {
        const hiccupId = bulkCheckbox.dataset.bulkCloseId;
        if (hiccupId) {
            if (bulkCheckbox.checked) {
                selectedBulkCloseIds.add(hiccupId);
            } else {
                selectedBulkCloseIds.delete(hiccupId);
            }
            renderBulkCloseBar(managementListState.items || []);
        }
        return;
    }

    const bulkSelectAll = event.target.closest('#bulk-close-select-all');
    if (bulkSelectAll) {
        const rows = Array.isArray(managementListState.items) ? managementListState.items : [];
        rows.filter(isBulkClosable).forEach((h) => {
            const id = String(h.hiccup_id);
            if (bulkSelectAll.checked) {
                selectedBulkCloseIds.add(id);
            } else {
                selectedBulkCloseIds.delete(id);
            }
        });
        renderAllTables();
        return;
    }

    const bulkCloseButton = event.target.closest('#bulk-close-action');
    if (bulkCloseButton) {
        event.preventDefault();
        await bulkCloseSelectedHiccups();
        return;
    }

    const ncTrigger = event.target.closest('[data-behavior="view-nc"]');
    if (ncTrigger) {
        event.preventDefault();
        closeOverlayModals();
        const hiccupId = ncTrigger.dataset.hiccup;
        const hiccup = myHiccupsData.find((entry) => entry.hiccup_id === hiccupId);
        const readonly = ncTrigger.dataset.ncReadonly === 'true' || hiccup?.status === 'Closed';
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
        closeOverlayModals();
        if (status) {
            await quickStatus(hiccupId, status);
        }
        return;
    }
    const detailBtn = event.target.closest('[data-hiccup-detail]');
    if (detailBtn) {
        event.preventDefault();
        const hiccupId = detailBtn.dataset.hiccupDetail;
        const accordionScope = detailBtn.dataset.accordionScope;
        if (accordionScope) {
            toggleHiccupAccordion(accordionScope, hiccupId);
            return;
        }
        const activeCollection = getActiveDetailCollection();
        const hiccup = activeCollection.find((h) => h.hiccup_id === hiccupId) || myHiccupsData.find((h) => h.hiccup_id === hiccupId);
        if (hiccup) {
            presentHiccupDetails(hiccup, activeCollection);
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

document.addEventListener('change', async (event) => {
    const pageSizeSelect = event.target.closest('[data-page-size-target]');
    if (!pageSizeSelect) {
        return;
    }
    const requestedSize = Number(pageSizeSelect.value || '');
    if (!PAGE_SIZE_OPTIONS.includes(requestedSize) || requestedSize === hiccupPageSize) {
        return;
    }
    hiccupPageSize = requestedSize;
    window.localStorage.setItem(PAGE_SIZE_STORAGE_KEY, String(hiccupPageSize));
    paginationState.raised = 1;
    paginationState.against = 1;
    paginationState.management = 1;
    paginationState.assigned = 1;
    await loadMyHiccups();
});

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && activeFilterDrawerId) {
        closeFilterDrawer(activeFilterDrawerId);
    }
});

window.addEventListener('popstate', () => {
    if (assignedViewMode) {
        paginationState.assigned = getUrlPageParam(1);
    } else if (window.managementView) {
        paginationState.management = getUrlPageParam(1);
    }
    loadMyHiccups();
});

document.addEventListener('DOMContentLoaded', () => {
    setupDensityControls();
    setupHiccupTabs();
    hydrateManagementStateFromUrl();
    if (typeof loadMyHiccups === 'function') {
        loadMyHiccups();
    }
});
