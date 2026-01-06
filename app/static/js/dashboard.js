const todayStatsMap = [
    { label: 'Raised', key: 'raised_today', hint: 'New hiccups coming in' },
    { label: 'Responded', key: 'responded_today', hint: 'Touched by the team' },
    { label: 'Closed', key: 'closed_today', hint: 'Resolved hiccups' },
    { label: 'Escalated', key: 'escalated_today', hint: 'Critical handoffs' },
];

function renderSummaryCards(stats = {}) {
    return todayStatsMap
        .map(
            ({ label, key, hint }) => `
                <article class="dashboard-summary-card">
                    <p class="dashboard-summary-card__value">${stats[key] ?? 0}</p>
                    <p class="dashboard-summary-card__label">${label}</p>
                    <p class="dashboard-summary-card__hint">${hint}</p>
                </article>
            `
        )
        .join('');
}

function renderStatusEntries(counts = {}) {
    const entries = Object.entries(counts || {});
    if (!entries.length) {
        return '<p class="dashboard-summary-card__hint">No records yet</p>';
    }
    return entries
        .map(
            ([label, value]) => `
                <div class="status-entry">
                    <strong>${label.replace(/_/g, ' ')}</strong>
                    <span>${value ?? 0}</span>
                </div>
            `
        )
        .join('');
}

function renderStatusCard(title, counts, badge) {
    return `
        <section class="dashboard-widget">
            <div class="dashboard-widget__header">
                <p class="dashboard-widget__title">${title}</p>
                ${badge ? `<span class="dashboard-widget__badge">${badge}</span>` : ''}
            </div>
            <div class="status-grid">
                ${renderStatusEntries(counts)}
            </div>
        </section>
    `;
}

function renderTodayWidget(stats = {}, overdue = {}) {
    const rows = todayStatsMap.map(({ label, key }) => ({
        label,
        value: stats[key] ?? 0,
    }));
    const totalOverdue = (overdue.response || 0) + (overdue.closure || 0);
    return `
        <section class="dashboard-widget dashboard-widget--wide">
            <div class="dashboard-widget__header">
                <p class="dashboard-widget__title">Today</p>
                <span class="dashboard-widget__badge">Daily snapshot</span>
            </div>
            <div class="today-stats">
                ${rows
                    .map(
                        ({ label, value }) => `
                            <div class="stat-row">
                                <strong>${label}</strong>
                                <span>${value}</span>
                            </div>
                        `
                    )
                    .join('')}
            </div>
            <div>
                <p class="trend-legend">Escalation heat</p>
                ${renderGlowMeter(totalOverdue, 20)}
            </div>
        </section>
    `;
}

function renderTrendList(alerts = []) {
    if (!alerts.length) {
        return '<p class="dashboard-summary-card__hint">No trend alerts</p>';
    }
    return `<ul class="trend-list">
        ${alerts
            .map(
                (alert) =>
                    `<li><strong>${alert.label}</strong><span class="text-xs text-slate-500"> ${alert.count} hiccups in last 7 days</span></li>`
            )
            .join('')}
    </ul>`;
}

function renderTrendWidget(alerts = []) {
    return `
        <section class="dashboard-widget">
            <div class="dashboard-widget__header">
                <p class="dashboard-widget__title">Trend Alerts</p>
                <span class="dashboard-widget__badge">Signals</span>
            </div>
            <p class="trend-legend">Live trend signals</p>
            ${renderTrendList(alerts)}
        </section>
    `;
}

function renderGlowMeter(value = 0, max = 10) {
    const percent = Math.min(100, Math.round((value / Math.max(1, max)) * 100));
    return `<div class="glow-meter"><span style="width:${percent}%"></span></div>`;
}

async function loadDashboard() {
    const root = document.querySelector('#dashboard-root');
    if (!root) {
        return;
    }
    try {
        const data = await fetchJSON('/api/dashboard/summary');
        const stats = data?.recent_stats || {};
        const overdue = data?.overdue || {};
        const cards = `
            <div class="dashboard-shell">
                <div class="dashboard-inner">
                    <div class="dashboard-summary">
                        ${renderSummaryCards(stats)}
                    </div>
                    <div class="dashboard-widgets">
                        ${renderStatusCard('My Raised Hiccups', data?.my_counts, 'Active')}
                        ${renderStatusCard('Assigned to Me', data?.assigned_counts, 'Watchlist')}
                        ${renderTodayWidget(stats, overdue)}
                        ${renderStatusCard(
                            'SLAs',
                            {
                                'response overdue': overdue.response,
                                'closure overdue': overdue.closure,
                            },
                            'Priority'
                        )}
                        ${renderTrendWidget(data?.trend_alerts)}
                    </div>
                </div>
            </div>
        `;
        root.innerHTML = cards;
    } catch (err) {
        console.error('Dashboard load failed', err);
        await showAlert({
            icon: 'error',
            title: 'Unable to load dashboard',
            text: err.message || 'Please try again.',
        });
    }
}

document.addEventListener('DOMContentLoaded', loadDashboard);
