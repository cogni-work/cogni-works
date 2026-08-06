// website/AudienceTabs.jsx — tabbed audience section
const { useState: useState_AT } = React;
const AUDIENCES = [
  {
    key: "consulting", label: "Consulting firms",
    head: "You compete on methodology depth, not headcount.",
    sub: "Every pitch costs days of senior capacity. We give that time back.",
    points: [
      "Account-specific pitches in 90 minutes",
      "Verified research reports in under 20",
      "60 scored trend candidates per scouting run",
      "Double Diamond with automated phase gates",
    ],
    cta: "Start with cogni-sales"
  },
  {
    key: "sales", label: "Sales organizations",
    head: "Standard decks stop working after the third customer.",
    sub: "Methodology-disciplined pitches, without tying up senior capacity on every deal.",
    points: [
      "Full Corporate Visions arc per opportunity",
      "DACH-grade account briefings reps can stand behind",
      "Buyer-role-specific value propositions",
      "Battle cards, demo scripts, objection handlers on tap",
    ],
    cta: "Start with cogni-portfolio"
  },
  {
    key: "marketing", label: "Marketing teams",
    head: "Your pipeline needs more content. Your budget doesn't.",
    sub: "16 channel-ready formats from a single narrative source — in consistent brand voice.",
    points: [
      "One narrative → blog, LinkedIn, whitepaper, newsletter",
      "Source-verified thought leadership, no invented stats",
      "Trend-driven relevance via TIPS scouting",
      "Website pages from the same content engine",
    ],
    cta: "Start with cogni-marketing"
  },
];

function AudienceTabs() {
  const [tab, setTab] = useState_AT("consulting");
  const cur = AUDIENCES.find(a => a.key === tab);
  return (
    <section className="cw-section cw-section-alt" id="who">
      <div className="cw-section-inner">
        <p className="cw-eyebrow">Who it's for</p>
        <h2 className="cw-section-h">Built for three kinds of team.</h2>
        <div className="cw-tabs">
          {AUDIENCES.map(a => (
            <button key={a.key}
              className={"cw-tab" + (tab === a.key ? " is-active" : "")}
              onClick={() => setTab(a.key)}>{a.label}</button>
          ))}
        </div>
        <div className="cw-aud-panel">
          <div>
            <h3 className="cw-aud-head">{cur.head}</h3>
            <p className="cw-aud-sub">{cur.sub}</p>
            <a className="cw-link-accent" href="#">{cur.cta} →</a>
          </div>
          <ul className="cw-aud-list">
            {cur.points.map((p,i) => (
              <li key={i}><span className="cw-check">✓</span>{p}</li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}
window.AudienceTabs = AudienceTabs;
