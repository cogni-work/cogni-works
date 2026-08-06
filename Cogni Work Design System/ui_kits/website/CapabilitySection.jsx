// website/CapabilitySection.jsx — card grid of capability areas
const CAPABILITIES = [
  { area: "Research", plug: "cogni-research", desc: "5–25 parallel web research agents producing cited, structured reports.", skills: 5, agents: 9 },
  { area: "Trend Intelligence", plug: "cogni-trends", desc: "TIPS scouting with bilingual DE/EN research and investment theme modeling.", skills: 6, agents: 9 },
  { area: "Portfolio Messaging", plug: "cogni-portfolio", desc: "IS/DOES/MEANS positioning across eight industry taxonomies.", skills: 19, agents: 20 },
  { area: "Content Production", plug: "cogni-marketing", desc: "16 channel-ready formats from a single narrative foundation.", skills: 11, agents: 3 },
  { area: "Sales Pitches", plug: "cogni-sales", desc: "Corporate Visions Why Change methodology with account-specific research.", skills: 1, agents: 4 },
  { area: "Visual Production", plug: "cogni-visual", desc: "Slide decks, web narratives, poster storyboards, infographics.", skills: 8, agents: 17 },
];

function CapabilityCard({ item, highlight }) {
  return (
    <article className={"cw-cap-card" + (highlight ? " is-highlight" : "")}>
      <p className="cw-cap-slug">{item.plug}</p>
      <h3 className="cw-cap-h">{item.area}</h3>
      <p className="cw-cap-desc">{item.desc}</p>
      <div className="cw-cap-foot">
        <span><b>{item.skills}</b> skills</span>
        <span><b>{item.agents}</b> agents</span>
      </div>
    </article>
  );
}

function CapabilitySection() {
  return (
    <section className="cw-section" id="plugins">
      <div className="cw-section-inner">
        <div className="cw-section-head">
          <div>
            <p className="cw-eyebrow">The platform</p>
            <h2 className="cw-section-h">Six capability areas.<br/>One consistent foundation.</h2>
          </div>
          <p className="cw-section-sub">Every plugin implements an established framework — Corporate Visions, Double Diamond, TIPS, IS/DOES/MEANS — rather than general-purpose text generation.</p>
        </div>
        <div className="cw-cap-grid">
          {CAPABILITIES.map((c,i) => <CapabilityCard key={c.plug} item={c} highlight={i===2}/>)}
        </div>
      </div>
    </section>
  );
}
window.CapabilitySection = CapabilitySection;
