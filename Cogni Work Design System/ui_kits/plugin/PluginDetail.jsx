// plugin/PluginDetail.jsx — centre panel showing plugin overview
function StatusPill({ tone, label }) {
  const map = {
    active: { bg: 'rgba(46,125,50,.1)', fg: '#2E7D32' },
    working: { bg: 'rgba(229,161,0,.12)', fg: '#9a6d00' },
    idle: { bg: 'var(--cw-surface)', fg: 'var(--fg-3)' },
  };
  const s = map[tone] || map.idle;
  return <span className="pw-pill" style={{ background: s.bg, color: s.fg }}>
    <span className="pw-pill-dot" style={{ background: s.fg }}/>
    {label}
  </span>;
}

function PluginDetail({ slug }) {
  const meta = {
    title: "cogni-sales",
    tagline: "B2B sales pitch generation with the Corporate Visions Why Change methodology.",
    skills: 1, agents: 4, commands: 2,
    desc: "Generates account-specific pitches using the Why Change arc — four research phases (Why Change, Why Now, Why You, Why Pay) each backed by a dedicated web research agent. Outputs sales-presentation.md and sales-proposal.md with sequential citations.",
  };
  return (
    <main className="pw-detail">
      <header className="pw-detail-head">
        <div>
          <p className="pw-eyebrow">Sales · Corporate Visions</p>
          <h1 className="pw-detail-title">{meta.title}</h1>
          <p className="pw-detail-tagline">{meta.tagline}</p>
        </div>
        <div className="pw-detail-actions">
          <StatusPill tone="active" label="Active"/>
          <button className="cw-btn-primary cw-btn-sm">Run pitch →</button>
        </div>
      </header>

      <div className="pw-stat-row">
        <div className="pw-stat"><div className="pw-stat-n">{meta.skills}</div><div className="pw-stat-l">Skill</div></div>
        <div className="pw-stat"><div className="pw-stat-n">{meta.agents}</div><div className="pw-stat-l">Agents</div></div>
        <div className="pw-stat"><div className="pw-stat-n">{meta.commands}</div><div className="pw-stat-l">Commands</div></div>
        <div className="pw-stat"><div className="pw-stat-n pw-stat-accent">12</div><div className="pw-stat-l">Runs this week</div></div>
      </div>

      <section className="pw-card">
        <div className="pw-card-head">
          <h3>Why Change arc · progress</h3>
          <span className="pw-badge">Run #0147 · Acme Corp</span>
        </div>
        <div className="pw-arc">
          {[
            { label: "Why Change", state: "done", agent: "research-why-change" },
            { label: "Why Now",    state: "done", agent: "research-why-now" },
            { label: "Why You",    state: "active", agent: "research-why-you" },
            { label: "Why Pay",    state: "pending", agent: "research-why-pay" },
          ].map(p => (
            <div key={p.label} className={"pw-arc-step is-" + p.state}>
              <div className="pw-arc-dot"/>
              <div className="pw-arc-label">{p.label}</div>
              <div className="pw-arc-agent">{p.agent}</div>
            </div>
          ))}
        </div>
      </section>

      <section className="pw-two-col">
        <div className="pw-card">
          <h3 className="pw-card-h">Outputs</h3>
          <ul className="pw-file-list">
            <li><span className="pw-file-ic">MD</span><div><div>sales-presentation.md</div><small>42 citations · 3,480 words</small></div><span className="pw-file-time">2m ago</span></li>
            <li><span className="pw-file-ic">MD</span><div><div>sales-proposal.md</div><small>28 citations · 2,140 words</small></div><span className="pw-file-time">2m ago</span></li>
            <li><span className="pw-file-ic">JSON</span><div><div>claims-manifest.json</div><small>70 claims · ready to verify</small></div><span className="pw-file-time">2m ago</span></li>
          </ul>
        </div>
        <div className="pw-card">
          <h3 className="pw-card-h">Pipeline position</h3>
          <div className="pw-pipe">
            <div className="pw-pipe-step"><div className="pw-pipe-n">cogni-portfolio</div><div className="pw-pipe-l">Upstream</div></div>
            <div className="pw-pipe-arrow">→</div>
            <div className="pw-pipe-step is-active"><div className="pw-pipe-n">cogni-sales</div><div className="pw-pipe-l">Current</div></div>
            <div className="pw-pipe-arrow">→</div>
            <div className="pw-pipe-step"><div className="pw-pipe-n">cogni-visual</div><div className="pw-pipe-l">Downstream</div></div>
          </div>
          <p className="pw-pipe-note">Receives portfolio positions; emits presentation-ready narrative to the visual renderer.</p>
        </div>
      </section>
    </main>
  );
}
window.PluginDetail = PluginDetail;
