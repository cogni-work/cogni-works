// plugin/Sidebar.jsx — plugin workspace sidebar
const PLUGINS = [
  { slug: "cogni-research", cat: "Research", skills: 5, agents: 9 },
  { slug: "cogni-trends", cat: "Trends", skills: 6, agents: 9 },
  { slug: "cogni-portfolio", cat: "Portfolio", skills: 19, agents: 20 },
  { slug: "cogni-marketing", cat: "Content", skills: 11, agents: 3 },
  { slug: "cogni-copywriting", cat: "Content", skills: 4, agents: 2 },
  { slug: "cogni-sales", cat: "Sales", skills: 1, agents: 4 },
  { slug: "cogni-visual", cat: "Visual", skills: 8, agents: 17 },
  { slug: "cogni-website", cat: "Website", skills: 6, agents: 3 },
  { slug: "cogni-wiki", cat: "Platform", skills: 7, agents: 0 },
  { slug: "cogni-workspace", cat: "Platform", skills: 5, agents: 0 },
];

function PluginSidebar({ active, onSelect }) {
  return (
    <aside className="pw-sidebar">
      <div className="pw-brand">
        <Mark size={32} tone="dark"/>
        <div>
          <div className="pw-brand-name">cogni<span className="hy">-</span>work</div>
          <div className="pw-brand-sub">insight-wave · v0.4.2</div>
        </div>
      </div>
      <div className="pw-side-section">
        <div className="pw-side-head">Workspace</div>
        <button className="pw-side-item is-active">
          <span className="pw-side-dot" style={{background:'#C8E62E'}}/>Acme · Consulting
        </button>
        <button className="pw-side-item">
          <span className="pw-side-dot" style={{background:'#6B7280'}}/>Siemens · Trends '26
        </button>
      </div>
      <div className="pw-side-section">
        <div className="pw-side-head">Plugins · 10 installed</div>
        {PLUGINS.map(p => (
          <button key={p.slug}
            className={"pw-plugin-item" + (active === p.slug ? " is-active" : "")}
            onClick={() => onSelect(p.slug)}>
            <div className="pw-plugin-main">
              <span className="pw-plugin-slug">{p.slug}</span>
              <span className="pw-plugin-cat">{p.cat}</span>
            </div>
            <div className="pw-plugin-meta">{p.skills}·{p.agents}</div>
          </button>
        ))}
      </div>
      <div className="pw-side-foot">
        <button className="pw-side-mini">⚙ Workspace health</button>
      </div>
    </aside>
  );
}
window.PluginSidebar = PluginSidebar;
