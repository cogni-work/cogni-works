// plugin/RunPanel.jsx — right-side terminal / activity log
const { useState: useState_RP, useEffect: useEffect_RP } = React;

const LINES = [
  { t: "→", s: "cmd",   txt: "/pitch --customer=Acme --portfolio=managed-services" },
  { t: "·", s: "meta",  txt: "routing to cogni-sales · version 1.4.0" },
  { t: "✓", s: "ok",    txt: "why-change agent: 12 sources retrieved (DACH + EN)" },
  { t: "✓", s: "ok",    txt: "why-now agent: 8 market signals scored" },
  { t: "•", s: "run",   txt: "why-you agent: extracting differentiation claims …" },
  { t: "·", s: "meta",  txt: "reading portfolio/acme/positions.json" },
  { t: "·", s: "meta",  txt: "17 IS/DOES/MEANS pairs loaded" },
  { t: "✓", s: "ok",    txt: "claims manifest seeded with 42 entries" },
  { t: "→", s: "cmd",   txt: "/copywrite sales-presentation.md --scope=full" },
  { t: "·", s: "meta",  txt: "framework: Pyramid · readability target 50-60" },
  { t: "✓", s: "ok",    txt: "readability score: 58.2 · active voice 84%" },
];

function RunPanel() {
  const [i, setI] = useState_RP(6);
  useEffect_RP(() => {
    if (i >= LINES.length) return;
    const t = setTimeout(() => setI(i + 1), 900);
    return () => clearTimeout(t);
  }, [i]);

  return (
    <aside className="pw-run">
      <div className="pw-run-head">
        <div>
          <div className="pw-run-title">Activity</div>
          <div className="pw-run-sub">Run #0147 · cogni-sales</div>
        </div>
        <div className="pw-run-status"><span className="pw-run-dot"/>Streaming</div>
      </div>
      <div className="pw-term">
        {LINES.slice(0, i).map((l, idx) => (
          <div key={idx} className={"pw-term-line is-" + l.s}>
            <span className="pw-term-t">{l.t}</span>
            <span>{l.txt}</span>
          </div>
        ))}
        {i < LINES.length && <div className="pw-term-cursor">▌</div>}
      </div>
      <div className="pw-run-foot">
        <div className="pw-chip">14s elapsed</div>
        <div className="pw-chip">$0.04</div>
        <div className="pw-chip pw-chip-accent">3 / 4 phases</div>
      </div>
    </aside>
  );
}
window.RunPanel = RunPanel;
