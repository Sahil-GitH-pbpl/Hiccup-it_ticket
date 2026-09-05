const app = document.querySelector('#app');
const assetBasePath = (window.ASSET_BASE_PATH || '/assets').replace(/\/$/, '');
const assetUrl = (path) =>
  `${assetBasePath}${String(path).startsWith('/') ? path : `/${path}`}`;
const roleFromToken = (token) => {
  try {
    const payload = token
      .split('.')[1]
      .replaceAll('-', '+')
      .replaceAll('_', '/');
    return JSON.parse(atob(payload)).role || null;
  } catch {
    return null;
  }
};
const state = {
  token: null,
  role: null,
  user: null,
  page: new URLSearchParams(window.location.search).get('page') || 'Dashboard',
  masters: {},
};
app.addEventListener('click', (event) => {
  const pageButton = event.target.closest('[data-page]');
  if (pageButton && app.contains(pageButton)) {
    event.preventDefault();
    navigate(pageButton.dataset.page);
    return;
  }
  const reportIssue = event.target.closest('#newTicket');
  if (!reportIssue) return;
  event.preventDefault();
  newTicket();
});
const esc = (v) =>
  String(v ?? '—').replace(
    /[&<>'"]/g,
    (c) =>
      ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;' })[
        c
      ],
  );
async function api(path, options = {}) {
  const headers = {
    ...(options.body ? { 'Content-Type': 'application/json' } : {}),
  };
  const r = await fetch(assetUrl('/api' + path), {
    ...options,
    headers: { ...headers, ...options.headers },
  });
  if (!r.ok) {
    const b = await r.json().catch(() => ({}));
    const error = Error(b.detail || r.statusText);
    error.status = r.status;
    throw error;
  }
  return r.status === 204 ? null : r.json();
}
async function upload(file, folder = 'documents') {
  const body = new FormData();
  body.append('file', file);
  body.append('folder', folder);
  const r = await fetch(assetUrl('/api/uploads'), {
    method: 'POST',
    body,
  });
  if (!r.ok) {
    const b = await r.json().catch(() => ({}));
    throw Error(b.detail || r.statusText);
  }
  return r.json();
}
const formData = (form) => Object.fromEntries(new FormData(form).entries());
function message(text, type = 'error') {
  const old = document.querySelector('.flash');
  if (old) old.remove();
  const p = document.createElement('p');
  p.className = `flash ${type}`;
  p.textContent = text;
  document.querySelector('.content')?.prepend(p);
}
function modal(title, html, onSubmit) {
  const box = document.createElement('div');
  box.className = 'modal';
  box.setAttribute('role', 'dialog');
  box.setAttribute('aria-modal', 'true');
  box.setAttribute('aria-label', title);
  box.innerHTML = `<section><div class="modalhead"><div><span class="modaleyebrow">AssetHub workflow</span><h2>${esc(title)}</h2></div><button type="button" class="secondary close" aria-label="Close popup">×</button></div><div class="modalbody">${html}</div></section>`;
  const close = () => {
    box.dispatchEvent(new CustomEvent('modal:close'));
    box.remove();
    document.body.classList.remove('modal-open');
  };
  box.querySelector('.close').onclick = close;
  box.addEventListener('click', (e) => {
    if (e.target === box) close();
  });
  const key = (e) => {
    if (e.key === 'Escape') {
      close();
      document.removeEventListener('keydown', key);
    }
  };
  document.addEventListener('keydown', key);
  const form = box.querySelector('form');
  if (form) {
    let footer = form.querySelector(':scope > .actions.wide');
    if (footer) {
      footer.classList.add('modalactions');
    } else {
      const submit = form.querySelector(':scope > button');
      if (submit) {
        footer = document.createElement('div');
        footer.className = 'modalactions wide';
        submit.before(footer);
        footer.append(submit);
      }
    }
    if (footer && !footer.querySelector('[data-cancel]')) {
      const cancel = document.createElement('button');
      cancel.type = 'button';
      cancel.className = 'secondary';
      cancel.dataset.cancel = 'true';
      cancel.textContent = 'Cancel';
      cancel.onclick = close;
      footer.prepend(cancel);
    }
    if (onSubmit)
      form.onsubmit = async (e) => {
        e.preventDefault();
        const submit = form.querySelector(
          '[type="submit"],.modalactions button:not([type="button"])',
        );
        const error = document.createElement('p');
        form.querySelector('.formerror')?.remove();
        try {
          if (submit) {
            submit.disabled = true;
            submit.dataset.label = submit.textContent;
            submit.textContent = 'Saving…';
          }
          await onSubmit(form);
          close();
        } catch (err) {
          error.className = 'error formerror wide';
          error.textContent = err.message;
          form.prepend(error);
        } finally {
          if (submit && box.isConnected) {
            submit.disabled = false;
            submit.textContent = submit.dataset.label || 'Save';
          }
        }
      };
  }
  document.body.classList.add('modal-open');
  document.body.append(box);
  bindUserSearch(box);
  setTimeout(
    () =>
      box
        .querySelector('input:not([type="hidden"]),select,textarea,button')
        ?.focus(),
    0,
  );
  return box;
}
function login() {
  window.location.href = `/login?next=${encodeURIComponent('/assets/')}`;
}
const pages = [
  'Dashboard',
  'Assets',
  'Service',
  'PM',
  'Calibration',
  'Contracts',
  'Movements',
  'Approvals',
  'Reports',
  'Masters',
  'Users',
];
const pageShortNames = {
  Dashboard: 'DB',
  Assets: 'AS',
  Service: 'SV',
  PM: 'PM',
  Calibration: 'CL',
  Contracts: 'CT',
  Movements: 'MV',
  Approvals: 'AP',
  Reports: 'RP',
  Masters: 'MS',
  Users: 'US',
};
const roleGroups = {
  admin: ['Administrator'],
  manager: ['Administrator', 'Asset Manager'],
  technical: ['Administrator', 'Asset Manager', 'Technician'],
};
function hasRole(group) {
  return (roleGroups[group] || []).includes(state.role);
}
function visibleAssetPages() {
  if (state.role === 'Administrator') return pages;
  if (state.role === 'Asset Manager')
    return [
      'Dashboard',
      'Assets',
      'Service',
      'PM',
      'Calibration',
      'Contracts',
      'Movements',
      'Reports',
      'Masters',
    ];
  if (state.role === 'Technician')
    return ['Dashboard', 'Assets', 'Service', 'PM', 'Calibration', 'Reports'];
  return ['Dashboard', 'Assets', 'Service'];
}
function shell() {
  const collapsed = localStorage.getItem('sidebar-collapsed') === 'true';
  const initialContent = app.querySelector('.content')?.innerHTML || '';
  const visiblePages = visibleAssetPages();
  if (!visiblePages.includes(state.page)) state.page = 'Dashboard';
  app.innerHTML = `<div class="app ${collapsed ? 'sidebar-collapsed' : ''}"><aside><button type="button" class="sidebar-toggle" aria-label="${collapsed ? 'Expand' : 'Collapse'} sidebar" title="${collapsed ? 'Expand' : 'Collapse'} sidebar">${collapsed ? '›' : '‹'}</button><div class="nav-label asset-nav-label">Asset Workspace</div><nav>${visiblePages.map((p) => `<a href="${assetUrl('/')}?page=${encodeURIComponent(p)}" data-page="${p}" title="${p}"><span class="nav-full">${p}</span><span class="nav-short">${pageShortNames[p]}</span></a>`).join('')}</nav></aside><main class="content"></main></div>`;
  if (state.page === 'Dashboard' && initialContent) {
    app.querySelector('.content').innerHTML = initialContent;
  }
  const layout = app.querySelector('.app');
  app.querySelector('.sidebar-toggle').onclick = (event) => {
    const isCollapsed = layout.classList.toggle('sidebar-collapsed');
    localStorage.setItem('sidebar-collapsed', String(isCollapsed));
    event.currentTarget.textContent = isCollapsed ? '›' : '‹';
    event.currentTarget.title = `${isCollapsed ? 'Expand' : 'Collapse'} sidebar`;
    event.currentTarget.setAttribute(
      'aria-label',
      `${isCollapsed ? 'Expand' : 'Collapse'} sidebar`,
    );
  };
  navigate(state.page);
}
function bindShellControls() {
  const layout = app.querySelector('.app');
  if (!layout) return;
  const toggle = app.querySelector('.sidebar-toggle');
  if (toggle && !toggle.dataset.bound) {
    toggle.dataset.bound = 'true';
    toggle.onclick = (event) => {
      const isCollapsed = layout.classList.toggle('sidebar-collapsed');
      localStorage.setItem('sidebar-collapsed', String(isCollapsed));
      event.currentTarget.textContent = isCollapsed ? '›' : '‹';
      event.currentTarget.title = `${isCollapsed ? 'Expand' : 'Collapse'} sidebar`;
      event.currentTarget.setAttribute(
        'aria-label',
        `${isCollapsed ? 'Expand' : 'Collapse'} sidebar`,
      );
    };
  }
}
async function navigate(page) {
  if (!pages.includes(page)) page = 'Dashboard';
  if (!visibleAssetPages().includes(page)) page = 'Dashboard';
  state.page = page;
  const nextUrl = `${assetUrl('/')}?page=${encodeURIComponent(page)}`;
  if (window.location.pathname.startsWith(assetBasePath)) {
    window.history.replaceState(null, '', nextUrl);
  }
  app
    .querySelectorAll('[data-page]')
    .forEach((b) => b.classList.toggle('active', b.dataset.page === page));
  const main = app.querySelector('.content');
  main.classList.add('is-loading');
  try {
    await {
      Dashboard: dashboard,
      Assets: assets,
      Service: service,
      PM: () => schedules('pm'),
      Calibration: () => schedules('calibration'),
      Contracts: contracts,
      Movements: movements,
      Approvals: approvals,
      Reports: reports,
      Masters: masters,
      Users: usersAdmin,
    }[page]();
  } catch (err) {
    main.innerHTML = `<p class="error">${esc(err.message)}</p>`;
  } finally {
    main.classList.remove('is-loading');
  }
}
const content = (html) => (app.querySelector('.content').innerHTML = html);
const tableColumnClass = (column) =>
  typeof column === 'object' && column.label === 'Actions'
    ? 'table-actions'
    : '';
const tableColumnLabel = (column) =>
  String(column.label || column)
    .replaceAll('_', ' ')
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
const statusChip = (value) => {
  const normalized = String(value || '').toUpperCase();
  const tone =
    /(CLOSED|COMPLETED|RESTORED|OPERATIONAL|APPROVED|ACTIVE|PASS)/.test(
      normalized,
    )
      ? 'success'
      : /(PENDING|DUE|AWAITING|MEDIUM|EXPIR)/.test(normalized)
        ? 'warning'
        : /(REPAIR|FAILED|REJECTED|LOST|STOLEN|HIGH|OVERDUE)/.test(normalized)
          ? 'danger'
          : 'info';
  return `<span class="chip chip-${tone}">${esc(value)}</span>`;
};
const table = (columns, rows) =>
  `<div class="tablewrap"><table class="table-cols-${columns.length}"><thead><tr>${columns.map((c) => `<th class="${tableColumnClass(c)}">${esc(tableColumnLabel(c))}</th>`).join('')}</tr></thead><tbody>${rows.length ? rows.map((r) => `<tr>${columns.map((c) => `<td class="${tableColumnClass(c)}" data-label="${esc(tableColumnLabel(c))}">${c.render ? c.render(r) : esc(r[c.key || c])}</td>`).join('')}</tr>`).join('') : `<tr class="empty-row"><td colspan="${columns.length}" class="empty">No records</td></tr>`}</tbody></table></div>`;
async function dashboard() {
  const d = await api('/dashboard');
  const items = [
    ['Total assets', 'total_assets'],
    ['Open tickets', 'open_tickets'],
    ['PM due / overdue', 'pm_due_or_overdue'],
    ['Under repair', 'assets_under_repair'],
    ['Repeat breakdowns', 'repeat_breakdown_alerts'],
    ['Due alerts', 'open_alerts'],
  ];
  content(
    `<h1>Dashboard</h1><p class="muted">Live operational overview</p><div class="cards">${items.map(([l, k]) => `<div class="card"><span>${l}</span><strong>${esc(d[k])}</strong></div>`).join('')}</div>`,
  );
}
async function getMasters(keys) {
  const vals = await Promise.all(keys.map((k) => api('/masters/' + k)));
  return Object.fromEntries(keys.map((k, i) => [k, vals[i]]));
}
const options = (rows, blank = 'Select') =>
  `<option value="">${blank}</option>${rows.map((x) => `<option value="${x.id}">${esc(optionLabel(x))}</option>`).join('')}`;
const optionsSelected = (rows, value, blank = 'Select') =>
  `<option value="">${blank}</option>${rows.map((x) => `<option value="${x.id}" ${String(x.id) === String(value) ? 'selected' : ''}>${esc(optionLabel(x))}</option>`).join('')}`;
const optionLabel = (row) => {
  if (!row) return '';
  if (row.asset_code) return `${row.asset_code} — ${row.asset_name || ''}`.trim();
  if (row.vendor_name) {
    const numbers = [
      row.mobile ? `Contact: ${row.mobile}` : '',
      row.vendor_phone ? `Vendor: ${row.vendor_phone}` : '',
      row.vendor_whatsapp && row.vendor_whatsapp !== row.vendor_phone
        ? `WhatsApp: ${row.vendor_whatsapp}`
        : '',
    ].filter(Boolean);
    return `${row.name} — ${row.vendor_name}${numbers.length ? ` (${numbers.join(', ')})` : ''}`;
  }
  if (row.mobile) return `${row.name} (${row.mobile})`;
  return row.name || '';
};
const employeeName = (id) =>
  state.masters.employees?.find((x) => String(x.id) === String(id))?.name || '';
function userSearchField(
  name,
  label,
  value = '',
  required = false,
  valueMode = 'id',
) {
  const displayValue = valueMode === 'name' ? value : employeeName(value);
  return `<label class="user-picker" data-user-picker data-value-mode="${valueMode}">${esc(label)}<input class="user-query" type="search" value="${esc(displayValue)}" placeholder="Search active staff by name, contact or designation" autocomplete="off" ${required ? 'required' : ''}><input type="hidden" name="${esc(name)}" value="${esc(value || '')}"><div class="user-results" hidden></div></label>`;
}
function bindUserSearch(container) {
  container.querySelectorAll('[data-user-picker]').forEach((picker) => {
    const query = picker.querySelector('.user-query');
    const value = picker.querySelector('input[type="hidden"]');
    const results = picker.querySelector('.user-results');
    let timer;
    const load = async () => {
      results.hidden = false;
      results.innerHTML = '<span class="user-result-status">Searching…</span>';
      try {
        const users = await api(
          `/active-users?q=${encodeURIComponent(query.value.trim())}&limit=20`,
        );
        results.innerHTML = users.length
          ? users
              .map(
                (user) =>
                  `<button type="button" class="user-result" data-id="${user.id}" data-name="${esc(user.name)}"><strong>${esc(user.name)}</strong><small>${esc([user.contact, user.designation].filter(Boolean).join(' · '))}</small></button>`,
              )
              .join('')
          : '<span class="user-result-status">No active user found</span>';
        results.querySelectorAll('[data-id]').forEach((button) => {
          button.onclick = () => {
            value.value =
              picker.dataset.valueMode === 'name'
                ? button.dataset.name
                : button.dataset.id;
            query.value = button.dataset.name;
            results.hidden = true;
            query.setCustomValidity('');
          };
        });
      } catch (error) {
        results.innerHTML = `<span class="user-result-status error">${esc(error.message)}</span>`;
      }
    };
    query.addEventListener('focus', load);
    query.addEventListener('input', () => {
      value.value = '';
      query.setCustomValidity(
        query.value.trim() ? 'Please select a user from search results' : '',
      );
      clearTimeout(timer);
      timer = setTimeout(load, 250);
    });
    query.addEventListener('blur', () =>
      setTimeout(() => (results.hidden = true), 180),
    );
  });
}
async function assets() {
  const q = new URLSearchParams(location.search).get('q') || '';
  const r = await api('/assets?q=' + encodeURIComponent(q) + '&size=100');
  const m = hasRole('manager')
    ? await getMasters([
        'categories',
        'types',
        'makes',
        'sites',
        'floors',
        'departments',
        'workstations',
        'employees',
        'contacts',
      ])
    : state.masters;
  state.masters = m;
  const assetActions = (x) => {
    const buttons = [`<button data-act="view" data-id="${x.id}">View</button>`];
    buttons.push(
      `<button data-act="report" data-id="${x.id}">Report issue</button>`,
    );
    if (hasRole('manager')) {
      buttons.push(
        `<button data-act="edit" data-id="${x.id}">Edit</button>`,
        `<button data-act="copy" data-id="${x.id}">Copy</button>`,
        `<button data-act="issue" data-id="${x.id}">${x.issued_to ? 'Return' : 'Issue'}</button>`,
        `<button data-act="transfer" data-id="${x.id}">Transfer</button>`,
        `<button data-act="qr" data-id="${x.id}">QR</button>`,
        `<button data-act="lifecycle" data-id="${x.id}" class="secondary">Lifecycle</button>`,
      );
    } else if (hasRole('technical')) {
      buttons.push(
        `<button data-act="transfer" data-id="${x.id}">Transfer</button>`,
        `<button data-act="qr" data-id="${x.id}">QR</button>`,
      );
    }
    return buttons.join('');
  };
  const assetRows = r.items
    .map(
      (x) =>
        `<article class="asset-row"><div class="asset-row-main"><span class="asset-code">${esc(x.asset_code)}</span><h3>${esc(x.asset_name)}</h3><p>${esc([x.category, x.type, x.serial_number ? `Serial: ${x.serial_number}` : ''].filter(Boolean).join(' · '))}</p></div><div class="asset-row-info"><span>Location</span><b>${esc(x.location || 'Not recorded')}</b></div><div class="asset-row-info"><span>Custody</span><b>${x.issued_to ? `Issued to ${esc(x.issued_to)}` : esc(x.staff_incharge || 'Not assigned')}</b></div><div class="asset-row-status">${statusChip(x.operational_status)}</div><div class="rowactions asset-row-actions">${assetActions(x)}</div></article>`,
    )
    .join('');
  const addAssetButton = hasRole('manager')
    ? '<button id="addAsset">+ Add asset</button>'
    : '';
  content(
    `<div class="pagehead"><div><h1>Assets</h1><p class="muted">${hasRole('manager') ? 'Register, issue, transfer and manage the complete asset lifecycle.' : 'View assets assigned to you and report service issues.'}</p></div>${addAssetButton}</div><form class="toolbar asset-searchbar" id="search"><input name="q" value="${esc(q)}" placeholder="Search asset code, name or serial number"><button>Search</button></form><section class="asset-list">${assetRows || '<p class="detail-empty">No assets found</p>'}</section>`,
  );
  document.querySelector('#search').onsubmit = (e) => {
    e.preventDefault();
    const val = new FormData(e.currentTarget).get('q');
    history.replaceState(null, '', '?q=' + encodeURIComponent(val));
    assets();
  };
  const addAsset = document.querySelector('#addAsset');
  if (addAsset) addAsset.onclick = () => assetForm();
  document.querySelectorAll('[data-act]').forEach(
    (b) =>
      (b.onclick = async () => {
        try {
          const a = await api('/assets/' + b.dataset.id);
          ({
            view: () => viewAsset(a),
            report: () => newTicket(a.id),
            edit: () => assetForm(a),
            copy: () => copyAsset(a),
            issue: () => issueAsset(a),
            transfer: () => transferAsset(a),
            qr: () => openQr(a),
            lifecycle: () => lifecycleAsset(a),
          })[b.dataset.act]();
        } catch (err) {
          message(err.message);
        }
      }),
  );
}
function copyAsset(source) {
  assetForm(
    {
      ...source,
      id: null,
      asset_code: null,
      serial_number: '',
      issued_to_employee_id: null,
      invoice_reference: '',
      primary_photo_path: null,
      photo_url: null,
      warranty_document_path: null,
      documents: [],
    },
    source.asset_code,
  );
}
const detailItem = (label, value, html = false) => {
  const present = value !== null && value !== undefined && value !== '';
  return `<div class="detail-item"><span>${esc(label)}</span><strong>${html && present ? value : esc(present ? value : 'Not recorded')}</strong></div>`;
};
const availableDetailItems = (items) =>
  items
    .filter(
      ([, value]) => value !== null && value !== undefined && value !== '',
    )
    .map(([label, value]) => detailItem(label, value))
    .join('');
const readableValue = (value) =>
  String(value || '')
    .replaceAll('_', ' ')
    .replace(/\b\w/g, (x) => x.toUpperCase());
const readableDateTime = (value) => {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return String(value);
  return date.toLocaleString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  });
};
async function openProtectedUpload(path) {
  const normalizedPath = String(path || '').replaceAll('\\', '/');
  const safePath = normalizedPath.split('/').map(encodeURIComponent).join('/');
  const requestUrl = assetUrl(`/api/uploads/${safePath}`);
  const fetchOptions = state.token
    ? { headers: { Authorization: `Bearer ${state.token}` } }
    : {};
  let response = await fetch(requestUrl, fetchOptions);
  if (!response.ok && state.token) {
    response = await fetch(requestUrl);
  }
  if (!response.ok) {
    throw Error(`Could not open document (${response.status})`);
  }
  const objectUrl = URL.createObjectURL(await response.blob());
  window.open(objectUrl, '_blank', 'noopener');
  setTimeout(() => URL.revokeObjectURL(objectUrl), 60000);
}
async function viewAsset(idOrAsset) {
  const a =
    typeof idOrAsset === 'object'
      ? idOrAsset
      : await api('/assets/' + idOrAsset);
  const contacts = (a.service_contacts || [])
    .map((contact) => {
      const vendor = contact.vendor;
      const contactDetails = availableDetailItems([
        ['Contact mobile', contact.mobile],
        ['Alternate mobile', contact.alternate_mobile],
        ['WhatsApp', contact.whatsapp],
        ['Email', contact.email],
        ['Contact notes', contact.notes],
      ]);
      const vendorDetails = vendor
        ? availableDetailItems([
            ['Vendor company', vendor.company_name],
            ['Company phone', vendor.phone],
            ['Vendor WhatsApp', vendor.whatsapp],
            ['Vendor email', vendor.email],
            ['Vendor GSTIN', vendor.gstin],
            ['Vendor address', vendor.address],
          ])
        : '';
      return `<article class="contact-card"><div class="contact-card-head"><div><b>${esc(contact.name)}</b><span>${esc(contact.designation || 'Service contact')}</span></div>${contact.is_primary ? '<span class="primary-badge">Primary</span>' : ''}</div>${contactDetails ? `<div class="detail-grid compact">${contactDetails}</div>` : ''}${vendorDetails ? `<div class="vendor-details"><h4>Vendor information</h4><div class="detail-grid compact">${vendorDetails}</div></div>` : '<p class="vendor-unlinked">No vendor is linked to this service contact.</p>'}</article>`;
    })
    .join('');
  const registeredDocuments = (a.documents || [])
    .map(
      (document) =>
        `<button type="button" class="document-link secondary" data-open-file="${esc(document.path)}"><span>${esc(document.title || document.document_type)}</span><small>${esc(document.document_type)}</small></button>`,
    )
    .join('');
  const warrantyDocument = a.warranty_document_path
    ? `<button type="button" class="document-link secondary" data-open-file="${esc(a.warranty_document_path)}"><span>Warranty document</span><small>${esc(a.warranty_document_path)}</small></button>`
    : '';
  const pmHistory = (a.pm_records || [])
    .map(
      (record) =>
        `<article class="history-card"><div class="history-card-head"><div><b>${esc(readableDateTime(record.completed_at))}</b><span>Performed by ${esc(record.performed_by || 'Not recorded')}</span></div>${record.cost ? `<em>Cost ${esc(record.cost)}</em>` : ''}</div>${record.remarks ? `<p>${esc(record.remarks)}</p>` : ''}<div class="document-list compact-documents">${record.service_report_path ? `<button type="button" class="document-link secondary" data-open-file="${esc(record.service_report_path)}"><span>Service report</span><small>${esc(record.service_report_path)}</small></button>` : ''}${record.calibration_certificate_path ? `<button type="button" class="document-link secondary" data-open-file="${esc(record.calibration_certificate_path)}"><span>Calibration certificate</span><small>${esc(record.calibration_result || 'Certificate')}</small></button>` : ''}</div></article>`,
    )
    .join('');
  const calibrationHistory = (a.calibration_records || [])
    .map(
      (record) =>
        `<article class="history-card"><div class="history-card-head"><div><b>${esc(readableDateTime(record.completed_at))}</b><span>Performed by ${esc(record.performed_by || 'Not recorded')}</span></div>${record.result ? `<em>${esc(record.result)}</em>` : ''}</div>${record.remarks ? `<p>${esc(record.remarks)}</p>` : ''}<div class="document-list compact-documents">${record.certificate_path ? `<button type="button" class="document-link secondary" data-open-file="${esc(record.certificate_path)}"><span>Calibration certificate</span><small>${esc(record.certificate_path)}</small></button>` : ''}</div></article>`,
    )
    .join('');
  const box = modal(
    `${a.asset_code} — ${a.asset_name}`,
    `<div class="asset-detail">${a.photo_url ? `<div class="detail-photo"><img src="${a.photo_url}" alt="${esc(a.asset_name)}"></div>` : ''}<section class="detail-section"><h3>Identity</h3><div class="detail-grid">${detailItem('Asset code', a.asset_code)}${detailItem('Asset name', a.asset_name)}${detailItem('Category', a.category)}${detailItem('Asset type', a.type)}${detailItem('Make', a.make)}${detailItem('Model', a.model)}${detailItem('Serial number', a.serial_number)}${detailItem('Criticality', a.criticality)}${detailItem('Operational status', statusChip(a.operational_status), true)}${detailItem('Lifecycle state', readableValue(a.lifecycle_state))}</div></section><section class="detail-section"><h3>Placement &amp; responsibility</h3><div class="detail-grid">${detailItem('Site', a.site)}${detailItem('Floor', a.floor)}${detailItem('Department', a.department)}${detailItem('Workstation', a.workstation)}${detailItem('Complete location', a.location)}${detailItem('Staff in-charge', a.staff_incharge)}${detailItem('In-charge designation', a.staff_incharge_designation)}${detailItem('In-charge contact', a.staff_incharge_contact)}${detailItem('Issued to', a.issued_to || 'Not issued')}${detailItem('Issued user designation', a.issued_to_designation)}${detailItem('Issued user contact', a.issued_to_contact)}</div></section><section class="detail-section"><h3>Purchase &amp; maintenance</h3><div class="detail-grid">${detailItem('Holding class', readableValue(a.holding_class))}${detailItem('Purchase date', a.purchase_date)}${detailItem('Purchase value', a.purchase_value)}${detailItem('Invoice reference', a.invoice_reference)}${detailItem('Warranty start', a.warranty_start_date)}${detailItem('Warranty end', a.warranty_end)}${detailItem('Useful life', a.useful_life_months ? `${a.useful_life_months} months` : null)}${detailItem('PM required', a.pm_required ? 'Yes' : 'No')}${detailItem('Calibration mode', readableValue(a.calibration_mode))}</div></section><section class="detail-section"><h3>PM History</h3><div class="history-list">${pmHistory || '<p class="detail-empty">No PM record completed yet</p>'}</div></section><section class="detail-section"><h3>Calibration History</h3><div class="history-list">${calibrationHistory || '<p class="detail-empty">No calibration record completed yet</p>'}</div></section><section class="detail-section"><h3>Service contacts &amp; vendors</h3><div class="contact-list">${contacts || '<p class="detail-empty">No service contact recorded</p>'}</div></section><section class="detail-section"><div class="detail-section-head"><h3>Documents</h3><button id="addDocument" type="button">+ Add document</button></div><div class="document-list">${warrantyDocument}${registeredDocuments || (!warrantyDocument ? '<p class="detail-empty">No documents attached</p>' : '')}</div></section><section class="detail-section"><h3>Asset timeline</h3><div class="timeline-list">${(a.timeline || []).map((event) => `<div class="timeline-event"><i></i><div><b>${esc(readableValue(event.type))}</b><p>${esc(event.message || 'No details')}</p><small>${esc(readableDateTime(event.at))}</small></div></div>`).join('') || '<p class="detail-empty">No timeline events</p>'}</div></section></div>`,
  );
  box.querySelector('#addDocument').onclick = () => documentForm(a);
  box.querySelectorAll('[data-open-file]').forEach((button) => {
    button.onclick = async () => {
      try {
        await openProtectedUpload(button.dataset.openFile);
      } catch (error) {
        message(error.message);
      }
    };
  });
}
function issueAsset(a) {
  const m = state.masters;
  if (a.issued_to) {
    modal(
      `Return ${a.asset_code}`,
      `<form class="formgrid"><label>Return condition<input name="condition"></label><label>Remarks<input name="remarks"></label><button>Confirm return</button></form>`,
      async (f) => {
        await api(`/assets/${a.id}/return`, {
          method: 'POST',
          body: JSON.stringify(formData(f)),
        });
        assets();
      },
    );
  } else {
    modal(
      `Issue ${a.asset_code}`,
      `<form class="formgrid">${userSearchField('employee_id', 'Issue to active user', '', true)}<label>Issue condition<input name="condition" value="Good"></label><label class="wide">Purpose / details<textarea name="details"></textarea></label><button>Confirm issue</button></form>`,
      async (f) => {
        const d = formData(f);
        d.employee_id = Number(d.employee_id);
        await api(`/assets/${a.id}/issue`, {
          method: 'POST',
          body: JSON.stringify(d),
        });
        assets();
      },
    );
  }
}
function transferAsset(a) {
  const m = state.masters;
  modal(
    `Transfer ${a.asset_code}`,
    `<form class="formgrid"><label>Site<select name="site_id" required>${optionsSelected(m.sites, a.site_id)}</select></label><label>Floor<select name="floor_id">${options(m.floors)}</select></label><label>Department<select name="department_id">${options(m.departments)}</select></label><label>Workstation<select name="workstation_id">${options(m.workstations)}</select></label><button>Confirm transfer</button></form>`,
    async (f) => {
      const d = formData(f);
      ['site_id', 'floor_id', 'department_id', 'workstation_id'].forEach(
        (k) => (d[k] = d[k] ? Number(d[k]) : null),
      );
      await api(`/assets/${a.id}/transfer`, {
        method: 'POST',
        body: JSON.stringify(d),
      });
      assets();
    },
  );
}
function lifecycleAsset(a) {
  modal(
    `Lifecycle request — ${a.asset_code}`,
    `<form class="formgrid"><label>Action<select name="action"><option>RETIRE</option><option>CONDEMN</option><option>LOST</option><option>STOLEN</option><option>DISPOSE</option></select></label><p class="wide muted">An administrator must approve this request.</p><button>Request approval</button></form>`,
    async (f) => {
      const action = formData(f).action;
      const r = await api(`/assets/${a.id}/lifecycle/${action}`, {
        method: 'POST',
        body: '{}',
      });
      message(`Created ${r.approval_number}`, 'notice');
    },
  );
}
async function openQr(a) {
  const r = await fetch(assetUrl(`/api/assets/${a.id}/qr.png`), {
  });
  if (!r.ok) {
    const b = await r.json().catch(() => ({}));
    throw Error(b.detail || 'Could not generate QR code');
  }
  const url = URL.createObjectURL(await r.blob());
  const box = modal(
    `QR code — ${a.asset_code}`,
    `<div class="qrpreview"><img src="${url}" alt="QR code for ${esc(a.asset_code)}"><p>Print this QR and attach it to the physical asset.</p><button id="downloadQr">Download QR</button></div>`,
  );
  box.querySelector('#downloadQr').onclick = () => {
    const link = document.createElement('a');
    link.href = url;
    link.download = `${a.asset_code}.png`;
    link.click();
  };
  box.addEventListener('modal:close', () => URL.revokeObjectURL(url), {
    once: true,
  });
}
function documentForm(a) {
  modal(
    `Add document — ${a.asset_code}`,
    `<form class="formgrid"><label>Document type<input name="document_type" required></label><label>Title<input name="title"></label><label class="wide">File<input type="file" name="file" required></label><button>Upload document</button></form>`,
    async (f) => {
      const fd = new FormData(f),
        file = fd.get('file'),
        stored = await upload(file, 'documents');
      await api(`/assets/${a.id}/documents`, {
        method: 'POST',
        body: JSON.stringify({
          document_type: fd.get('document_type'),
          title: fd.get('title') || null,
          file_path: stored.path,
        }),
      });
      viewAsset(a.id);
    },
  );
}
async function service() {
  const rows = await api('/tickets?open_only=true');
  const serviceActions = (x) => {
    const buttons = [`<button data-ticket-view="${x.id}">View</button>`];
    if (hasRole('technical')) {
      if (x.status === 'REPORTED')
        buttons.push(`<button data-action="assign" data-id="${x.id}">Assign</button>`);
      if (['REPORTED', 'ASSIGNED'].includes(x.status))
        buttons.push(`<button data-action="start-inspection" data-id="${x.id}">Inspect</button>`);
      if (['REPORTED', 'ASSIGNED', 'INSPECTION'].includes(x.status))
        buttons.push(`<button data-action="escalate" data-id="${x.id}">Escalate</button>`);
      if (['REPORTED', 'ASSIGNED', 'INSPECTION', 'AWAITING_VENDOR'].includes(x.status))
        buttons.push(`<button data-action="start-repair" data-id="${x.id}">Repair</button>`);
      if (x.status === 'UNDER_REPAIR')
        buttons.push(`<button data-part="${x.id}">Add part</button><button data-action="restore" data-id="${x.id}">Restore</button>`);
      if (x.status === 'RESTORED')
        buttons.push(`<button data-action="close" data-id="${x.id}">Close</button>`);
    }
    return `<div class="rowactions">${buttons.join('')}</div>`;
  };
  content(
    `<div class="pagehead"><div><h1>Service tickets</h1><p class="muted">${hasRole('technical') ? 'Report, inspect, escalate, repair, restore and close breakdowns.' : 'Track and report service issues for assets assigned to you.'}</p></div><button id="newTicket">+ Report issue</button></div>${table([{ label: 'Ticket', render: (x) => `<b>${esc(x.ticket_number)}</b><br>${esc(x.asset)}` }, 'complaint', 'priority', { label: 'Status', render: (x) => statusChip(x.status) }, { label: 'Actions', render: serviceActions }], rows)}`,
  );
  document
    .querySelectorAll('[data-ticket-view]')
    .forEach((b) => (b.onclick = () => viewTicket(b.dataset.ticketView)));
  document
    .querySelectorAll('[data-part]')
    .forEach((b) => (b.onclick = () => partForm(b.dataset.part)));
  document
    .querySelectorAll('[data-action]')
    .forEach(
      (button) =>
        (button.onclick = () =>
          serviceActionForm(button.dataset.action, button.dataset.id)),
    );
}
async function serviceActionForm(action, ticketId) {
  const config = {
    assign: {
      title: 'Assign service ticket',
      button: 'Assign ticket',
      fields: `${userSearchField('assigned_to', 'Assign to staff', '', true, 'name')}<label class="wide">Instructions / notes<textarea name="notes" placeholder="Add instructions for the assigned staff"></textarea></label>`,
    },
    'start-inspection': {
      title: 'Start inspection',
      button: 'Start inspection',
      fields:
        '<label class="wide">Inspection notes<textarea name="notes" placeholder="Initial symptoms, checks to perform or observations"></textarea></label>',
    },
    'start-repair': {
      title: 'Start repair',
      button: 'Start repair',
      fields:
        '<label class="wide">Repair details<textarea name="notes" placeholder="Diagnosis, planned repair work or vendor response" required></textarea></label>',
    },
    restore: {
      title: 'Restore asset',
      button: 'Mark as restored',
      fields:
        '<label class="wide">Work completed<textarea name="notes" placeholder="Describe the repair completed and current working condition" required></textarea></label>',
    },
    close: {
      title: 'Close service ticket',
      button: 'Close ticket',
      fields:
        '<div class="wide action-confirm-note"><b>Asset must be restored before closing.</b><span>This action completes the service workflow.</span></div><label class="wide">Closure notes<textarea name="notes" placeholder="Final verification or handover notes"></textarea></label>',
    },
  };
  let selected = config[action];
  if (action === 'escalate') {
    const vendors = await api('/masters/vendors');
    selected = {
      title: 'Escalate to vendor',
      button: 'Escalate ticket',
      fields: `<label>Vendor<select name="vendor_id" required>${options(vendors, 'Select vendor')}</select></label><label>Vendor reference<input name="vendor_reference" placeholder="Quotation, complaint or job reference"></label><label class="wide">Escalation notes<textarea name="notes" placeholder="Issue details shared with vendor" required></textarea></label>`,
    };
  }
  if (!selected) return;
  modal(
    selected.title,
    `<form class="formgrid service-action-form">${selected.fields}<div class="actions wide"><button>${selected.button}</button></div></form>`,
    async (form) => {
      const data = formData(form);
      data.notes = data.notes || null;
      if ('vendor_id' in data)
        data.vendor_id = data.vendor_id ? Number(data.vendor_id) : null;
      if ('vendor_reference' in data)
        data.vendor_reference = data.vendor_reference || null;
      await api(`/tickets/${ticketId}/${action}`, {
        method: 'POST',
        body: JSON.stringify(data),
      });
      await service();
    },
  );
}
async function newTicket(selectedAssetId = null) {
  const a = (await api('/assets?size=100')).items;
  modal(
    'Report service issue',
    `<form class="formgrid"><label>Asset<select name="asset_id" required>${options(a)}</select></label><label>Priority<select name="priority"><option>Normal</option><option>High</option><option>Critical</option><option>Low</option></select></label><label class="wide">Complaint<textarea name="complaint" required minlength="2"></textarea></label><button>Raise ticket</button></form>`,
    async (f) => {
      const d = formData(f);
      d.asset_id = Number(d.asset_id);
      await api('/tickets', { method: 'POST', body: JSON.stringify(d) });
      service();
    },
  );
}
async function viewTicket(id) {
  const t = await api('/tickets/' + id);
  const parts = (t.parts || [])
    .map(
      (p) =>
        `<div class="ticket-part-row"><b>${esc(p.description)}</b><span>Qty ${esc(p.quantity)}${p.unit_cost ? ` · Cost ${esc(p.unit_cost)}` : ''}</span>${p.remarks ? `<small>${esc(p.remarks)}</small>` : ''}</div>`,
    )
    .join('');
  const events = (t.events || [])
    .map(
      (e) =>
        `<div class="ticket-event-row"><b>${esc(readableValue(e.type))}</b><p>${esc(e.notes || 'No notes')}</p>${e.performed_by ? `<span>By ${esc(e.performed_by)}</span>` : ''}<small>${esc(readableDateTime(e.at))}</small></div>`,
    )
    .join('');
  modal(
    t.ticket_number,
    `<div class="ticket-detail-view"><div class="ticket-summary-card"><div><span>Asset</span><b>${esc(t.asset.asset_code)}</b><small>${esc(t.asset.asset_name || '')}</small></div><div><span>Status</span>${statusChip(`${t.priority} · ${t.status}`)}</div><div><span>Downtime</span><b>${t.downtime_minutes == null ? '—' : esc(t.downtime_minutes)} min</b></div></div><section class="detail-section"><h3>Ticket details</h3><div class="detail-grid compact"><div class="detail-item"><span>Complaint</span><strong>${esc(t.complaint)}</strong></div><div class="detail-item"><span>Reported by</span><strong>${esc(t.reported_by || '—')}</strong></div><div class="detail-item"><span>Reported at</span><strong>${esc(readableDateTime(t.reported_at))}</strong></div><div class="detail-item"><span>Assigned to</span><strong>${esc(t.assigned_to || 'Not assigned')}</strong></div><div class="detail-item"><span>Vendor</span><strong>${esc(t.vendor || 'Not escalated')}</strong></div><div class="detail-item"><span>Vendor reference</span><strong>${esc(t.vendor_reference || '—')}</strong></div></div></section><section class="detail-section"><h3>Repair parts</h3><div class="ticket-list-block">${parts || '<p class="detail-empty">No parts added</p>'}</div></section><section class="detail-section"><h3>Events</h3><div class="ticket-list-block">${events || '<p class="detail-empty">No events recorded</p>'}</div></section></div>`,
  );
}
function partForm(id) {
  modal(
    'Add repair part',
    `<form class="formgrid"><label>Description<input name="description" required></label><label>Quantity<input type="number" step="0.01" name="quantity" value="1" required></label><label>Unit cost<input type="number" step="0.01" name="unit_cost"></label><label>Remarks<input name="remarks"></label><button>Add part</button></form>`,
    async (f) => {
      const d = formData(f);
      d.quantity = Number(d.quantity);
      d.unit_cost = d.unit_cost ? Number(d.unit_cost) : null;
      d.remarks = d.remarks || null;
      await api(`/tickets/${id}/parts`, {
        method: 'POST',
        body: JSON.stringify(d),
      });
      service();
    },
  );
  if (selectedAssetId)
    document.querySelector('.modal [name="asset_id"]').value = String(selectedAssetId);
}
async function schedules(kind) {
  if (!hasRole('technical')) return navigate('Dashboard');
  const base = '/' + kind,
    title = kind === 'pm' ? 'Preventive maintenance' : 'Calibration',
    rows = await api(base + '/schedules');
  const addScheduleButton = hasRole('manager') ? '<button id="addSchedule">+ Add schedule</button>' : '';
  content(
    `<div class="pagehead"><div><h1>${title}</h1><p class="muted">Schedule compliance, due dates and completion records.</p></div>${addScheduleButton}</div>${table(['asset', { label: 'Next due', key: 'next_due' }, { label: 'Frequency', render: (x) => (kind === 'pm' && x.pm_period_months ? `${esc(x.pm_period_months)} ${x.pm_period_months === 1 ? 'month' : 'months'}` : `${esc(x.frequency_days)} days`) }, { label: 'State', render: (x) => (x.overdue ? 'Overdue' : x.active === false ? 'Inactive' : 'Active') }, { label: 'Actions', render: (x) => `<div class="rowactions schedule-actions"><button data-complete="${x.id}">Complete</button></div>` }], rows)}`,
  );
  const addSchedule = document.querySelector('#addSchedule');
  if (addSchedule) addSchedule.onclick = async () => {
    const allAssets = (await api('/assets?size=100')).items;
    const a =
      kind === 'pm'
        ? allAssets.filter(
            (asset) =>
              asset.pm_required &&
              [1, 3, 6, 12].includes(Number(asset.pm_period_months)) &&
              !rows.some((row) => row.asset === asset.asset_code),
          )
        : allAssets;
    if (!a.length) {
      message(
        kind === 'pm'
          ? 'No asset is available. First enable PM and select its period in the asset form.'
          : 'No asset is available.',
      );
      return;
    }
    const firstPeriod = Number(a[0]?.pm_period_months || 0);
    const box = modal(
      `Add ${title.toLowerCase()} schedule`,
      `<form class="formgrid"><label>Asset<select name="asset_id" required>${options(a)}</select></label>${kind === 'pm' ? `<label>PM frequency<input name="frequency_label" value="" readonly><small>Taken automatically from the selected asset.</small></label>` : '<label>Frequency days<input type="number" name="frequency_days" value="90" min="1" required></label>'}<label>Next due<input type="date" name="next_due" required></label><button>Save</button></form>`,
      async (f) => {
        const d = formData(f);
        d.asset_id = Number(d.asset_id);
        if (kind === 'pm') {
          const selected = a.find((asset) => asset.id === d.asset_id);
          d.frequency_days = { 1: 30, 3: 90, 6: 180, 12: 365 }[
            Number(selected.pm_period_months)
          ];
          delete d.frequency_label;
        } else d.frequency_days = Number(d.frequency_days);
        await api(base + '/schedules', {
          method: 'POST',
          body: JSON.stringify(d),
        });
        schedules(kind);
      },
    );
    if (kind === 'pm') {
      const assetSelect = box.querySelector('[name="asset_id"]');
      const frequency = box.querySelector('[name="frequency_label"]');
      const nextDueInput = box.querySelector('[name="next_due"]');
      const syncPeriod = () => {
        const selected = a.find(
          (asset) => String(asset.id) === assetSelect.value,
        );
        const months = Number(selected?.pm_period_months || firstPeriod);
        frequency.value = months
          ? `${months} ${months === 1 ? 'month' : 'months'}`
          : '';
        nextDueInput.value = addCalendarMonths(localDateValue(), months);
      };
      assetSelect.addEventListener('change', syncPeriod);
      syncPeriod();
    }
  };
  document.querySelectorAll('[data-complete]').forEach(
    (b) =>
      (b.onclick = () =>
        completeSchedule(
          kind,
          rows.find((row) => String(row.id) === b.dataset.complete),
        )),
  );
}
function localDateValue(value = new Date()) {
  const year = value.getFullYear();
  const month = String(value.getMonth() + 1).padStart(2, '0');
  const day = String(value.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}
function localDateTimeValue(value = new Date()) {
  const hours = String(value.getHours()).padStart(2, '0');
  const minutes = String(value.getMinutes()).padStart(2, '0');
  const seconds = String(value.getSeconds()).padStart(2, '0');
  return `${localDateValue(value)}T${hours}:${minutes}:${seconds}`;
}
function addCalendarMonths(dateText, months) {
  if (!dateText || !months) return '';
  const [year, month, day] = dateText.split('-').map(Number);
  const target = new Date(year, month - 1 + Number(months), 1);
  const lastDay = new Date(
    target.getFullYear(),
    target.getMonth() + 1,
    0,
  ).getDate();
  target.setDate(Math.min(day, lastDay));
  return localDateValue(target);
}
function completeSchedule(kind, schedule) {
  const pm = kind === 'pm';
  const today = localDateValue();
  const period = Number(schedule?.pm_period_months || 0);
  const nextDue = pm ? addCalendarMonths(today, period) : '';
  const box = modal(
    `Complete ${pm ? 'maintenance' : 'calibration'}`,
    `<form class="formgrid pm-completion-form">${userSearchField('performed_by', 'Performed by (staff)', '', true, 'name')}${pm ? `<label>Completion date<input type="date" name="completion_date" value="${today}" max="${today}" required><small>Date on which preventive maintenance was completed.</small></label><label>PM frequency<input value="${period ? `${period} ${period === 1 ? 'month' : 'months'}` : 'Not configured'}" readonly><small>Taken from this asset's maintenance setting.</small></label><label>Next preventive maintenance<input type="date" name="next_due" value="${nextDue}" readonly required><small>Calculated automatically from completion date + PM frequency.</small></label><label>Cost<input type="number" step="0.01" min="0" name="cost"></label><label class="wide">Remarks<textarea name="remarks" required placeholder="Work performed, observations and parts replaced"></textarea></label><label class="wide">Service report<input type="file" name="report" required><small>Attach the completed preventive-maintenance report.</small></label>` : '<label>Result<select name="result"><option>PASS</option><option>FAIL</option></select></label><label class="wide">Remarks<textarea name="remarks"></textarea></label><label class="wide">Certificate<input type="file" name="certificate"></label>'}<div class="actions wide"><button>Complete ${pm ? 'maintenance' : 'calibration'}</button></div></form>`,
    async (f) => {
      const fd = new FormData(f),
        completionDate = fd.get('completion_date'),
        completedAt = pm
          ? `${completionDate}T${localDateTimeValue().split('T')[1]}`
          : localDateTimeValue();
      let d;
      if (pm) {
        const stored = await upload(fd.get('report'), 'pm-reports');
        d = {
          completed_at: completedAt,
          performed_by: fd.get('performed_by'),
          next_due: fd.get('next_due'),
          remarks: fd.get('remarks'),
          service_report_path: stored.path,
          cost: fd.get('cost') ? Number(fd.get('cost')) : null,
          calibration_performed: false,
        };
      } else {
        const file = fd.get('certificate'),
          stored =
            file && file.name
              ? await upload(file, 'calibration-certificates')
              : null;
        d = {
          completed_at: completedAt,
          performed_by: fd.get('performed_by'),
          result: fd.get('result'),
          certificate_path: stored?.path || null,
          remarks: fd.get('remarks') || null,
        };
      }
      await api(`/${kind}/schedules/${schedule.id}/complete`, {
        method: 'POST',
        body: JSON.stringify(d),
      });
      schedules(kind);
    },
  );
  if (pm) {
    const completion = box.querySelector('[name="completion_date"]');
    const due = box.querySelector('[name="next_due"]');
    completion.addEventListener('change', () => {
      due.value = addCalendarMonths(completion.value, period);
    });
  }
}
async function contracts() {
  if (!hasRole('manager')) return navigate('Dashboard');
  const [rows, vendors, assetsList] = await Promise.all([
    api('/contracts'),
    api('/masters/vendors'),
    api('/assets?size=100'),
  ]);
  content(
    `<div class="pagehead"><div><h1>Contracts</h1><p class="muted">AMC, CMC and warranty coverage.</p></div><button id="addContract">+ Add contract</button></div>${table(['contract_number', 'type', 'vendor', { label: 'Covered assets', render: (x) => (x.assets || []).map(esc).join(', ') || 'None' }, 'start_date', 'end_date', { label: 'Status', render: (x) => statusChip(x.status) }, { label: 'Actions', render: (x) => `<div class="rowactions"><button data-contract-view="${x.id}">View</button>${x.status === 'RENEWAL_APPROVED' ? `<button data-complete-renewal="${x.id}">Complete renewal</button>` : x.status === 'RENEWAL_PENDING' ? '<button disabled>Awaiting approval</button>' : `<button data-renew="${x.id}">Request renewal</button>`}</div>` }], rows)}`,
  );
  document.querySelector('#addContract').onclick = () =>
    modal(
      'Add service contract',
      `<form class="formgrid"><label>Type<select name="contract_type"><option>AMC</option><option>CMC</option><option>WARRANTY</option></select></label><label>Vendor<select name="vendor_id" required>${options(vendors)}</select></label><label>Start date<input type="date" name="start_date" required></label><label>End date<input type="date" name="end_date" required></label><label>Value<input type="number" step="0.01" name="value"></label><label>Reference<input name="reference_number"></label><label class="wide">Covered assets<select name="asset_ids" multiple required>${assetsList.items.map((a) => `<option value="${a.id}">${esc(a.asset_code + ' — ' + a.asset_name)}</option>`).join('')}</select></label><label class="wide">Notes<textarea name="notes"></textarea></label><button>Save contract</button></form>`,
      async (f) => {
        const fd = new FormData(f),
          d = formData(f);
        d.vendor_id = Number(d.vendor_id);
        d.value = d.value ? Number(d.value) : null;
        d.reference_number = d.reference_number || null;
        d.notes = d.notes || null;
        d.asset_ids = fd.getAll('asset_ids').map(Number);
        await api('/contracts', { method: 'POST', body: JSON.stringify(d) });
        contracts();
      },
    );
  document.querySelectorAll('[data-renew]').forEach(
    (b) =>
      (b.onclick = async () => {
        await api(`/contracts/${b.dataset.renew}/renew`, {
          method: 'POST',
          body: '{}',
        });
        await contracts();
        message('Renewal approval request created', 'notice');
      }),
  );
  document.querySelectorAll('[data-contract-view]').forEach((button) => {
    button.onclick = () =>
      viewContract(
        rows.find((row) => String(row.id) === button.dataset.contractView),
      );
  });
  document.querySelectorAll('[data-complete-renewal]').forEach((button) => {
    button.onclick = () =>
      completeRenewalForm(
        rows.find((row) => String(row.id) === button.dataset.completeRenewal),
      );
  });
}
function viewContract(contract) {
  modal(
    contract.contract_number,
    `<div class="formgrid"><p><b>Type</b><br>${esc(contract.type)}</p><p><b>Vendor</b><br>${esc(contract.vendor)}</p><p><b>Coverage</b><br>${esc(contract.start_date)} to ${esc(contract.end_date)}</p><p><b>Value</b><br>${esc(contract.value || 'Not recorded')}</p><p class="wide"><b>Covered assets</b><br>${(contract.assets || []).map(esc).join(', ') || 'None'}</p><div class="wide"><h3>Renewal history</h3>${(contract.renewals || []).map((renewal) => `<p><b>${esc(renewal.status)}</b><br>${esc(renewal.old_end_date || '—')} → ${esc(renewal.new_end_date || 'Pending details')}</p>`).join('') || '<p>No renewal requests</p>'}</div></div>`,
  );
}
function completeRenewalForm(contract) {
  modal(
    `Complete renewal — ${contract.contract_number}`,
    `<form class="formgrid"><p class="wide muted">Approval complete. Enter the final renewed contract details.</p><label>New start date<input type="date" name="start_date" required></label><label>New end date<input type="date" name="end_date" required></label><label>Renewal value<input type="number" step="0.01" name="value" value="${esc(contract.value || '')}"></label><label>Reference number<input name="reference_number" value="${esc(contract.reference_number || '')}"></label><label class="wide">Renewal document<input type="file" name="document" accept=".pdf,.png,.jpg,.jpeg,.webp"></label><label class="wide">Notes<textarea name="notes"></textarea></label><button>Apply renewal</button></form>`,
    async (form) => {
      const fd = new FormData(form);
      const file = fd.get('document');
      const stored = file?.name ? await upload(file, 'contract-renewals') : null;
      const data = {
        start_date: fd.get('start_date'),
        end_date: fd.get('end_date'),
        value: fd.get('value') ? Number(fd.get('value')) : null,
        reference_number: fd.get('reference_number') || null,
        document_path: stored?.path || null,
        notes: fd.get('notes') || null,
      };
      await api(`/contracts/${contract.id}/complete-renewal`, {
        method: 'POST',
        body: JSON.stringify(data),
      });
      await contracts();
      message(`${contract.contract_number} renewed successfully`, 'notice');
    },
  );
}
async function movements() {
  if (!hasRole('manager')) return navigate('Dashboard');
  const [rows, assetsList] = await Promise.all([
    api('/movements'),
    api('/assets?size=100'),
  ]);
  content(
    `<div class="pagehead"><div><h1>External movements</h1><p class="muted">Gate passes and returns.</p></div><button id="addMovement">+ Create gate pass</button></div>${table(['gate_pass_number', 'asset', 'destination', 'expected_return', 'status', { label: 'Actions', render: (x) => (x.status !== 'RETURNED' ? `<button data-return="${x.id}">Record return</button>` : '') }], rows)}`,
  );
  document.querySelector('#addMovement').onclick = () =>
    modal(
      'Create external movement',
      `<form class="formgrid"><label>Asset<select name="asset_id" required>${options(assetsList.items)}</select></label><label>Type<select name="movement_type"><option>REPAIR</option><option>CALIBRATION</option><option>DEMO</option></select></label><label>Destination<input name="destination" required></label><label>Expected return<input type="date" name="expected_return"></label><label class="wide">Remarks<textarea name="remarks"></textarea></label><button>Create gate pass</button></form>`,
      async (f) => {
        const d = formData(f);
        d.asset_id = Number(d.asset_id);
        d.expected_return = d.expected_return || null;
        d.remarks = d.remarks || null;
        await api('/movements', { method: 'POST', body: JSON.stringify(d) });
        movements();
      },
    );
  document.querySelectorAll('[data-return]').forEach(
    (b) =>
      (b.onclick = async () => {
        await api(`/movements/${b.dataset.return}/return`, {
          method: 'POST',
          body: '{}',
        });
        movements();
      }),
  );
}
async function approvals() {
  if (!hasRole('admin')) return navigate('Dashboard');
  const rows = await api('/approvals');
  content(
    `<h1>Approvals</h1>${table(['approval_number', 'action_type', 'details', 'status', { label: 'Actions', render: (x) => (x.status === 'PENDING' ? `<div class="rowactions"><button data-decision="approve" data-id="${x.id}">Approve</button><button class="secondary" data-decision="reject" data-id="${x.id}">Reject</button></div>` : '') }], rows)}`,
  );
  document.querySelectorAll('[data-decision]').forEach(
    (b) =>
      (b.onclick = async () => {
        const approval = rows.find((row) => String(row.id) === b.dataset.id);
        await api(`/approvals/${b.dataset.id}/${b.dataset.decision}`, {
          method: 'POST',
          body: '{}',
        });
        await approvals();
        if (
          b.dataset.decision === 'approve' &&
          approval?.action_type === 'CONTRACT_RENEWAL'
        )
          message(
            'Renewal approved. Final details can now be entered from Contracts.',
            'notice',
          );
      }),
  );
}
async function reports() {
  if (!hasRole('technical')) return navigate('Dashboard');
  const [r, a] = await Promise.all([api('/reports/summary'), api('/alerts')]);
  content(
    `<h1>Reports and alerts</h1>${table(['asset', 'type', 'message', 'due_on'], a)}<h2>Repeat breakdowns</h2>${table(['asset', 'ticket_count', 'downtime_minutes'], r.repeat_breakdowns)}<h2>Downtime by asset</h2>${table(['asset', 'ticket_count', 'downtime_minutes'], r.downtime_by_asset)}<h2>Overdue PM</h2>${table(['asset', 'next_due'], r.pm_overdue)}`,
  );
}
async function usersAdmin(query = '') {
  if (!hasRole('admin')) return navigate('Dashboard');
  const [users, roles] = await Promise.all([
    api(`/users?q=${encodeURIComponent(query)}&limit=7`),
    api('/roles'),
  ]);
  const roleOptions = (selected) =>
    roles
      .map(
        (role) =>
          `<option value="${role.id}" ${String(role.id) === String(selected) ? 'selected' : ''}>${esc(role.name)}</option>`,
      )
      .join('');
  content(
    `<div class="pagehead"><div><h1>Users &amp; roles</h1><p class="muted">Search active users and assign access according to their responsibilities.</p></div><span class="user-total">Showing ${users.length} of max 7</span></div><form class="toolbar" id="userRoleSearch"><input name="q" value="${esc(query)}" placeholder="Search name, contact or designation"><button>Search</button></form>${table([{ label: 'User', render: (user) => `<b>${esc(user.name)}</b><br><small>${esc(user.designation || 'No designation')}</small>` }, 'contact', { label: 'Status', render: (user) => statusChip(user.status) }, { label: 'Role', render: (user) => `<select class="role-select" data-role-user="${user.id}">${roleOptions(user.role_id)}</select>` }, { label: 'Actions', render: (user) => `<div class="rowactions"><button data-save-user-role="${user.id}">Save role</button></div>` }], users)}`,
  );
  document.querySelector('#userRoleSearch').onsubmit = (event) => {
    event.preventDefault();
    usersAdmin(new FormData(event.currentTarget).get('q').trim());
  };
  document.querySelectorAll('[data-save-user-role]').forEach((button) => {
    button.onclick = async () => {
      const userId = button.dataset.saveUserRole;
      const select = document.querySelector(`[data-role-user="${userId}"]`);
      button.disabled = true;
      try {
        const updated = await api(`/users/${userId}/role`, {
          method: 'PUT',
          body: JSON.stringify({ role_id: Number(select.value) }),
        });
        await usersAdmin(query);
        message(`${updated.name} is now ${updated.role}`, 'notice');
      } catch (error) {
        button.disabled = false;
        message(error.message);
      }
    };
  });
}
async function masters() {
  if (!hasRole('manager')) return navigate('Dashboard');
  const kinds = [
      ['categories', 'Asset categories'],
      ['types', 'Asset types'],
      ['makes', 'Makes'],
      ['sites', 'Sites'],
      ['departments', 'Departments'],
      ['vendors', 'Vendors'],
      ['contacts', 'Service contacts'],
      ['workstations', 'Workstations'],
    ],
    kind = state.masterKind || 'categories';
  const [rows, categories, vendors, sites, departments] = await Promise.all([
    api('/masters/' + kind),
    api('/masters/categories'),
    api('/masters/vendors'),
    api('/masters/sites'),
    api('/masters/departments'),
  ]);
  content(
    `<div class="pagehead"><div><h1>Master data</h1><p class="muted">Values used throughout asset registration and service workflows.</p></div><button id="addMaster">+ Add</button></div><form class="toolbar"><select name="kind">${kinds.map(([v, l]) => `<option value="${v}" ${v === kind ? 'selected' : ''}>${l}</option>`).join('')}</select></form>${table(['id', 'name', { label: 'Actions', render: (row) => `<div class="rowactions"><button data-master-edit="${row.id}">Edit</button><button class="danger" data-master-delete="${row.id}">Delete</button></div>` }], rows)}`,
  );
  document.querySelector('[name=kind]').onchange = (e) => {
    state.masterKind = e.target.value;
    masters();
  };
  document.querySelector('#addMaster').onclick = () => {
    let extra = '';
    if (kind === 'types')
      extra = `<label>Category<select name="category_id" required>${options(categories)}</select></label>`;
    if (kind === 'contacts')
      extra = `<label>Vendor<select name="vendor_id">${options(vendors, 'No vendor')}</select></label><label>Mobile<input name="mobile"></label><label>Email<input type="email" name="email"></label>`;
    if (kind === 'vendors')
      extra =
        '<label>Phone<input name="phone"></label><label>Email<input type="email" name="email"></label><label class="wide">Address<textarea name="address"></textarea></label>';
    if (kind === 'workstations')
      extra = `<label>Site<select name="site_id" required>${options(sites)}</select></label><label>Department<select name="department_id">${options(departments)}</select></label>`;
    modal(
      `Add ${kinds.find((x) => x[0] === kind)[1]}`,
      `<form class="formgrid"><label>Name<input name="name" required></label>${extra}<button>Add</button></form>`,
      async (f) => {
        const d = formData(f);
        let path = '/masters/' + kind;
        if (kind === 'vendors') {
          path = '/vendors';
          d.company_name = d.name;
          delete d.name;
          d.phone = d.phone || null;
          d.email = d.email || null;
          d.address = d.address || null;
        } else if (kind === 'contacts') {
          path = '/contacts';
          d.vendor_id = d.vendor_id ? Number(d.vendor_id) : null;
          d.mobile = d.mobile || null;
          d.email = d.email || null;
        } else if (kind === 'types') d.category_id = Number(d.category_id);
        else if (kind === 'workstations') {
          path = '/workstations';
          d.site_id = Number(d.site_id);
          d.department_id = d.department_id ? Number(d.department_id) : null;
        }
        await api(path, { method: 'POST', body: JSON.stringify(d) });
        masters();
      },
    );
  };
  const refs = { categories, vendors, sites, departments };
  document.querySelectorAll('[data-master-edit]').forEach((button) => {
    button.onclick = () =>
      editMasterForm(
        kind,
        rows.find((row) => String(row.id) === button.dataset.masterEdit),
        refs,
      );
  });
  document.querySelectorAll('[data-master-delete]').forEach((button) => {
    button.onclick = () =>
      deleteMaster(
        kind,
        rows.find((row) => String(row.id) === button.dataset.masterDelete),
      );
  });
}
function editMasterForm(kind, row, refs) {
  let extra = '';
  if (kind === 'types')
    extra = `<label>Category<select name="category_id" required>${optionsSelected(refs.categories, row.category_id)}</select></label>`;
  if (kind === 'contacts')
    extra = `<label>Vendor<select name="vendor_id">${optionsSelected(refs.vendors, row.vendor_id, 'No vendor')}</select></label><label>Mobile<input name="mobile" value="${esc(row.mobile || '')}"></label><label>Email<input type="email" name="email" value="${esc(row.email || '')}"></label>`;
  if (kind === 'vendors')
    extra = `<label>Phone<input name="phone" value="${esc(row.phone || '')}"></label><label>Email<input type="email" name="email" value="${esc(row.email || '')}"></label><label class="wide">Address<textarea name="address">${esc(row.address || '')}</textarea></label>`;
  if (kind === 'workstations')
    extra = `<label>Site<select name="site_id" required>${optionsSelected(refs.sites, row.site_id)}</select></label><label>Department<select name="department_id">${optionsSelected(refs.departments, row.department_id)}</select></label>`;
  modal(
    `Edit ${row.name}`,
    `<form class="formgrid"><label>Name<input name="name" value="${esc(row.name)}" required></label>${extra}<button>Save changes</button></form>`,
    async (form) => {
      const data = formData(form);
      ['category_id', 'site_id', 'department_id', 'vendor_id'].forEach(
        (key) => (data[key] = data[key] ? Number(data[key]) : null),
      );
      ['phone', 'mobile', 'email', 'address'].forEach((key) => {
        if (key in data) data[key] = data[key] || null;
      });
      await api(`/masters/${kind}/${row.id}`, {
        method: 'PUT',
        body: JSON.stringify(data),
      });
      await masters();
    },
  );
}
function deleteMaster(kind, row) {
  modal(
    `Delete ${row.name}`,
    `<form class="formgrid"><p class="wide">Are you sure you want to delete <b>${esc(row.name)}</b>? Records already used by assets or history cannot be deleted.</p><div class="actions wide"><button class="danger">Delete permanently</button></div></form>`,
    async () => {
      await api(`/masters/${kind}/${row.id}`, { method: 'DELETE' });
      await masters();
    },
  );
}
function assetForm(a = {}) {
  const m = state.masters,
    edit = Boolean(a.id),
    allowedSiteKey = (name) =>
      String(name || '')
        .toUpperCase()
        .replace(/[^A-Z0-9]/g, ''),
    assetSites = m.sites
      .filter((site) => ['GK1', 'GKI', 'GURGAON'].includes(allowedSiteKey(site.name)))
      .map((site) => ({
        ...site,
        name: ['GK1', 'GKI'].includes(allowedSiteKey(site.name))
          ? 'GK-1'
          : 'Gurgaon',
      }))
      .sort((left, right) =>
        left.name === 'GK-1' ? -1 : right.name === 'GK-1' ? 1 : 0,
      ),
    selectedSiteId = a.site_id || assetSites[0]?.id || '';
  const box = modal(
    edit ? `Edit ${a.asset_code}` : 'Register asset',
    `<form class="formgrid assetform">
    <div class="asset-form-intro wide"><b>${edit ? 'Update asset information' : 'Add a new asset'}</b><span>Fields marked Required must be filled. You can update the remaining details later.</span></div>
    <h3 class="wide"><span>1</span><b>Asset identity</b><small>Basic information used to identify and search this asset.</small></h3>
    <label>Asset name<input name="asset_name" value="${esc(a.asset_name || '')}" placeholder="Example: Biochemistry Analyzer" required><small>Use the common name employees recognize.</small></label>
    <label>Category<select name="category_id" required>${optionsSelected(m.categories, a.category_id)}</select></label>
    <label>Asset type<select name="asset_type_id" required></select></label><button type="button" class="link inline-add" data-add="types">+ Add type</button>
    <label>Make<select name="make_id">${optionsSelected(m.makes, a.make_id)}</select></label><button type="button" class="link inline-add" data-add="makes">+ Add make</button>
    <label>Model<input name="model_text" value="${esc(a.model || '')}" placeholder="Manufacturer model number"></label>
    <label>Serial number<input name="serial_number" value="${esc(a.serial_number || '')}" placeholder="Printed on the asset"></label>
    <label>Criticality<select name="criticality">${[
      ['C1', 'C1 — High'],
      ['C2', 'C2 — Medium'],
      ['C3', 'C3 — Low'],
    ]
      .map(
        ([value, label]) =>
          `<option value="${value}" ${value === (a.criticality || 'C3') ? 'selected' : ''}>${label}</option>`,
      )
      .join(
        '',
      )}</select><small>Choose the operational impact if this asset stops working.</small></label>
    <h3 class="wide"><span>2</span><b>Location &amp; responsibility</b><small>Where the asset is kept and who is responsible for it.</small></h3>
    <label>Site<select name="current_site_id" required>${optionsSelected(assetSites, selectedSiteId)}</select><small>Available locations: GK-1 and Gurgaon.</small></label>
    <label>Floor<select name="current_floor_id"></select></label>
    <label>Department<select name="current_department_id">${optionsSelected(m.departments, a.department_id)}</select></label>
    <label>Workstation<select name="current_workstation_id"></select></label><button type="button" class="link inline-add" data-add="workstations">+ Add workstation</button>
    ${userSearchField('staff_incharge_employee_id', 'Staff in-charge', a.staff_incharge_employee_id, true)}
    ${userSearchField('issued_to_employee_id', 'Issued to (optional)', a.issued_to_employee_id)}
    <h3 class="wide"><span>3</span><b>Service support</b><small>People or vendors to contact for repair and support.</small></h3>
    <label>Primary service contact<select name="primary_service_contact_id" required>${optionsSelected(m.contacts, a.primary_service_contact_id)}</select></label><button type="button" class="link inline-add" data-add="contacts">+ Add contact</button>
    <label class="wide">Additional service contacts<select name="service_contact_ids" multiple>${m.contacts.map((x) => `<option value="${x.id}" ${(a.service_contacts || []).some((c) => c.id === x.id) ? 'selected' : ''}>${esc(optionLabel(x))}</option>`).join('')}</select><small>Optional. Hold Ctrl while clicking to select more than one contact.</small></label>
    <h3 class="wide"><span>4</span><b>Purchase &amp; warranty</b><small>Ownership, invoice and warranty information.</small></h3>
    <label>Ownership type<select name="holding_class">${[
      ['', 'Not specified'],
      ['COMPANY_OWNED', 'Company owned'],
      ['CONTRACT_LEASED', 'Contract / leased'],
      ['VENDOR_HOSTED', 'Vendor hosted'],
      ['TEMPORARY_DEMO_LOANER', 'Temporary demo / loaner'],
    ]
      .map(
        ([value, label]) =>
          `<option value="${value}" ${value === (a.holding_class || '') ? 'selected' : ''}>${label}</option>`,
      )
      .join('')}</select></label>
    <label>Purchase date<input type="date" name="purchase_date" value="${esc(a.purchase_date || '')}"></label>
    <label>Purchase value<input type="number" step="0.01" name="purchase_value" value="${esc(a.purchase_value || '')}"></label>
    <label>Invoice reference<input name="invoice_reference" value="${esc(a.invoice_reference || '')}" placeholder="Invoice or purchase reference"></label>
    <label>Warranty start<input type="date" name="warranty_start_date" value="${esc(a.warranty_start_date || '')}"></label>
    <label>Warranty end<input type="date" name="warranty_end_date" value="${esc(a.warranty_end || '')}"></label>
    <label>Useful life (months)<input type="number" min="1" name="useful_life_months" value="${esc(a.useful_life_months || '')}" placeholder="Example: 60"></label>
    <h3 class="wide"><span>5</span><b>Maintenance schedule</b><small>Set calibration and preventive-maintenance frequency only when required.</small></h3>
    <label>Calibration requirement<select name="calibration_mode"><option value="NOT_REQUIRED" ${(a.calibration_mode || 'NOT_REQUIRED') === 'NOT_REQUIRED' ? 'selected' : ''}>Non Required</option><option value="REQUIRED" ${a.calibration_mode === 'REQUIRED' ? 'selected' : ''}>Required</option></select></label>
    <label data-calibration-period>Calibration period<select name="calibration_period_months"><option value="">Select period</option>${[
      [1, '1 month'],
      [3, '3 months'],
      [6, '6 months'],
      [12, '1 year'],
    ]
      .map(
        ([value, label]) =>
          `<option value="${value}" ${Number(a.calibration_period_months) === value ? 'selected' : ''}>${label}</option>`,
      )
      .join('')}</select></label>
    <label class="maintenance-check"><input type="checkbox" name="pm_required" ${a.pm_required ? 'checked' : ''}><span><b>Preventive maintenance required</b><small>Enable this to choose a recurring PM period.</small></span></label><label data-pm-period>Preventive maintenance period<select name="pm_period_months"><option value="">Select period</option>${[
      [1, '1 month'],
      [3, '3 months'],
      [6, '6 months'],
      [12, '1 year'],
    ]
      .map(
        ([value, label]) =>
          `<option value="${value}" ${Number(a.pm_period_months) === value ? 'selected' : ''}>${label}</option>`,
      )
      .join('')}</select></label>
    <h3 class="wide"><span>6</span><b>Documents &amp; media</b><small>Add a clear asset photo and its warranty document.</small></h3>
    <label>Primary asset photo<input type="file" name="primary_photo" accept=".png,.jpg,.jpeg,.webp"><small>${a.photo_url ? 'Current photo will be kept unless replaced.' : 'Accepted: PNG, JPG or WEBP'}</small></label>
    <label>Warranty document<input type="file" name="warranty_document" accept=".pdf,.png,.jpg,.jpeg,.webp"><small>${a.warranty_document_path ? 'Current document will be kept unless replaced.' : 'Accepted: PDF, PNG, JPG or WEBP'}</small></label>
    <div class="actions wide asset-form-actions"><span>Review the required fields before saving.</span><button>${edit ? 'Save changes' : 'Create asset'}</button></div>
  </form>`,
    async (f) => {
      const fd = new FormData(f),
        d = formData(f);
      [
        'category_id',
        'asset_type_id',
        'make_id',
        'current_site_id',
        'current_floor_id',
        'current_department_id',
        'current_workstation_id',
        'staff_incharge_employee_id',
        'issued_to_employee_id',
        'primary_service_contact_id',
        'useful_life_months',
        'calibration_period_months',
        'pm_period_months',
      ].forEach((k) => (d[k] = d[k] ? Number(d[k]) : null));
      [
        'holding_class',
        'purchase_date',
        'purchase_value',
        'invoice_reference',
        'warranty_start_date',
        'warranty_end_date',
      ].forEach((k) => (d[k] = d[k] || null));
      d.pm_required = fd.has('pm_required');
      d.service_contact_ids = fd
        .getAll('service_contact_ids')
        .map(Number)
        .filter(Boolean);
      const photo = fd.get('primary_photo'),
        warranty = fd.get('warranty_document');
      d.primary_photo_path = photo?.name
        ? (await upload(photo, 'photos')).path
        : a.primary_photo_path || null;
      d.warranty_document_path = warranty?.name
        ? (await upload(warranty, 'warranty')).path
        : a.warranty_document_path || null;
      delete d.primary_photo;
      delete d.warranty_document;
      await api(edit ? `/assets/${a.id}` : '/assets', {
        method: edit ? 'PUT' : 'POST',
        body: JSON.stringify(d),
      });
      await assets();
    },
  );
  const form = box.querySelector('form'),
    field = (n) => form.elements.namedItem(n);
  const toggleCalibrationPeriod = () => {
    const required = field('calibration_mode').value === 'REQUIRED';
    const period = field('calibration_period_months');
    period.disabled = !required;
    period.required = required;
    if (!required) period.value = '';
    period
      .closest('[data-calibration-period]')
      .classList.toggle('field-disabled', !required);
  };
  const togglePmPeriod = () => {
    const required = field('pm_required').checked;
    const period = field('pm_period_months');
    period.disabled = !required;
    period.required = required;
    if (!required) period.value = '';
    period
      .closest('[data-pm-period]')
      .classList.toggle('field-disabled', !required);
  };
  const refill = (select, rows, value, blank = 'Select') => {
    select.innerHTML = optionsSelected(rows, value, blank);
  };
  const filterLocations = () => {
    const site = field('current_site_id').value,
      dept = field('current_department_id').value;
    const floor = field('current_floor_id'),
      workstation = field('current_workstation_id');
    const floorValue = floor.value || String(a.floor_id || ''),
      workstationValue = workstation.value || String(a.workstation_id || '');
    refill(
      floor,
      m.floors
        .filter((x) => !site || String(x.site_id) === site)
        .sort((left, right) => {
          const order = [
            'Basement',
            'Ground Floor',
            'First Floor',
            'Second Floor',
            'Third Floor',
          ];
          return order.indexOf(left.name) - order.indexOf(right.name);
        }),
      floorValue,
    );
    refill(
      workstation,
      m.workstations.filter(
        (x) =>
          (!site || String(x.site_id) === site) &&
          (!dept || String(x.department_id || '') === dept),
      ),
      workstationValue,
    );
  };
  const filterTypes = () => {
    const value = field('asset_type_id').value || String(a.asset_type_id || '');
    refill(
      field('asset_type_id'),
      m.types.filter(
        (x) =>
          !field('category_id').value ||
          String(x.category_id) === field('category_id').value,
      ),
      value,
    );
  };
  field('category_id').addEventListener('change', () => {
    field('asset_type_id').value = '';
    filterTypes();
  });
  field('current_site_id').addEventListener('change', () => {
    field('current_floor_id').value = '';
    field('current_workstation_id').value = '';
    filterLocations();
  });
  field('current_department_id').addEventListener('change', () => {
    field('current_workstation_id').value = '';
    filterLocations();
  });
  field('calibration_mode').addEventListener('change', toggleCalibrationPeriod);
  field('pm_required').addEventListener('change', togglePmPeriod);
  toggleCalibrationPeriod();
  togglePmPeriod();
  filterTypes();
  filterLocations();
  form.querySelectorAll('[data-add]').forEach(
    (button) =>
      (button.onclick = async () => {
        const kind = button.dataset.add,
          vendors = kind === 'contacts' ? await api('/masters/vendors') : [];
        const extra =
          kind === 'types'
            ? `<label>Category<select name="category_id" required>${optionsSelected(m.categories, field('category_id').value)}</select></label>`
            : kind === 'contacts'
              ? `<label>Vendor<select name="vendor_id">${options(vendors, 'No vendor')}</select></label><label>Mobile No<input name="mobile" placeholder="Contact number"></label><label>Email<input type="email" name="email" placeholder="Contact email"></label>`
              : kind === 'workstations'
                ? `<label>Site<select name="site_id" required>${optionsSelected(m.sites, field('current_site_id').value)}</select></label><label>Department<select name="department_id">${optionsSelected(m.departments, field('current_department_id').value)}</select></label>`
                : '';
        modal(
          `Add ${kind === 'types' ? 'type' : kind === 'makes' ? 'make' : kind === 'contacts' ? 'contact' : 'workstation'}`,
          `<form class="formgrid"><label>Name<input name="name" required></label>${extra}<button>Add</button></form>`,
          async (inlineForm) => {
            const d = formData(inlineForm);
            let path = '/masters/' + kind;
            if (kind === 'types') d.category_id = Number(d.category_id);
            if (kind === 'contacts') {
              path = '/contacts';
              d.vendor_id = d.vendor_id ? Number(d.vendor_id) : null;
              d.mobile = d.mobile || null;
              d.email = d.email || null;
            }
            if (kind === 'workstations') {
              path = '/workstations';
              d.site_id = Number(d.site_id);
              d.department_id = d.department_id
                ? Number(d.department_id)
                : null;
            }
            const created = await api(path, {
              method: 'POST',
              body: JSON.stringify(d),
            });
            m[kind] = await api('/masters/' + kind);
            if (kind === 'types') {
              filterTypes();
              field('asset_type_id').value = String(created.id);
            }
            if (kind === 'makes') {
              refill(field('make_id'), m.makes, created.id);
            }
            if (kind === 'contacts') {
              refill(
                field('primary_service_contact_id'),
                m.contacts,
                created.id,
              );
              const selected = [
                ...field('service_contact_ids').selectedOptions,
              ].map((x) => x.value);
              field('service_contact_ids').innerHTML = m.contacts
                .map(
                  (x) =>
                    `<option value="${x.id}" ${selected.includes(String(x.id)) ? 'selected' : ''}>${esc(optionLabel(x))}</option>`,
                )
                .join('');
            }
            if (kind === 'workstations') {
              filterLocations();
              field('current_workstation_id').value = String(created.id);
            }
            document.body.classList.add('modal-open');
          },
        );
      }),
  );
}

async function boot() {
  bindShellControls();
  try {
    const me = await api('/auth/me');
    state.user = me;
    state.role = me.role;
    shell();
  } catch (error) {
    if (error?.status === 401) {
      window.location.href = `/login?next=${encodeURIComponent('/assets/')}`;
      return;
    }
    app.innerHTML = `<main class="login"><section><h1>Asset Management</h1><p class="error">Asset Management database is not reachable right now. Please start/import the asset database and refresh this page.</p></section></main>`;
  }
}
boot();
