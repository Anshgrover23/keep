const ABS = { position: "absolute" };

export const MENU_H = 32;
const RIGHT_PAD = 14;
const CLOCK_W = 170;
const GAP = 10;
const KEEP_HIT = 30;
const AFTER_KEEP = GAP + 16 + GAP + 27 + GAP + 17 + GAP + 16 + GAP + CLOCK_W + RIGHT_PAD;
export const KEEP_EXTRA_X = 1280 - AFTER_KEEP - KEEP_HIT / 2;
export const KEEP_EXTRA_Y = MENU_H / 2;
const DOCK_ICON = 60;

function AppleLogo({ color }) {
  return (
    <svg width="16" height="19" viewBox="0 0 170 170" aria-hidden style={{ display: "block", color }}>
      <path
        fill="currentColor"
        d="M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.197-2.12-9.973-3.17-14.34-3.17-4.58 0-9.492 1.05-14.746 3.17-5.262 2.13-9.501 3.24-12.742 3.35-4.929 0.21-9.842-1.96-14.746-6.52-3.13-2.73-7.045-7.41-11.735-14.04-5.032-7.08-9.169-15.29-12.41-24.65-3.471-10.11-5.211-19.9-5.211-29.378 0-10.857 2.346-20.221 7.045-28.068 3.693-6.303 8.606-11.275 14.755-14.925s12.793-5.51 19.948-5.629c3.915 0 9.049 1.211 15.429 3.591 6.362 2.388 10.447 3.599 12.238 3.599 1.339 0 5.877-1.416 13.57-4.239 7.275-2.618 13.415-3.702 18.445-3.275 13.63 1.1 23.87 6.473 30.68 16.153-12.19 7.386-18.22 17.731-18.1 31.002 0.11 10.337 3.86 18.939 11.23 25.769 3.34 3.17 7.07 5.62 11.22 7.36-0.9 2.61-1.85 5.11-2.86 7.51zM119.11 7.24c0 8.102-2.96 15.667-8.86 22.669-7.12 8.324-15.732 13.134-25.071 12.375-0.119-0.972-0.188-1.995-0.188-3.07 0-7.778 3.386-16.102 9.399-22.908 3.002-3.446 6.82-6.311 11.45-8.597 4.62-2.252 8.99-3.497 13.1-3.71 0.12 1.083 0.17 2.166 0.17 3.241z"
      />
    </svg>
  );
}

function Wifi({ color }) {
  return (
    <svg width="17" height="13" viewBox="0 0 16 12" aria-hidden style={{ color }}>
      <path fill="currentColor" d="M8 9.5a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3z" />
      <path fill="currentColor" d="M8 6.5c1.66 0 3.14.69 4.22 1.78a.75.75 0 1 1-1.06 1.06A4.5 4.5 0 0 0 8 8a4.5 4.5 0 0 0-3.16 1.34.75.75 0 1 1-1.06-1.06A5.98 5.98 0 0 1 8 6.5z" />
      <path fill="currentColor" d="M8 3c2.76 0 5.26 1.12 7.07 2.93a.75.75 0 1 1-1.06 1.06A8.48 8.48 0 0 0 8 4.5a8.48 8.48 0 0 0-6.01 2.49.75.75 0 1 1-1.06-1.06A9.98 9.98 0 0 1 8 3z" />
    </svg>
  );
}

function Battery({ color }) {
  return (
    <svg width="27" height="13" viewBox="0 0 27 13" aria-hidden>
      <rect x="0.6" y="1.4" width="20" height="10.2" rx="2.4" fill="none" stroke={color} strokeWidth="1.3" />
      <rect x="2.4" y="3.2" width="16.4" height="6.6" rx="1.2" fill={color} />
      <rect x="21.4" y="4.4" width="2.2" height="4.2" rx="0.6" fill={color} />
    </svg>
  );
}

function ControlCenter({ color }) {
  return (
    <svg width="16" height="16" viewBox="0 0 15 15" aria-hidden style={{ color }}>
      <path fill="currentColor" fillRule="evenodd" d="M3.25 2C1.73122 2 0.5 3.23122 0.5 4.75C0.5 6.26878 1.73122 7.5 3.25 7.5H11.75C13.2688 7.5 14.5 6.26878 14.5 4.75C14.5 3.23122 13.2688 2 11.75 2H3.25ZM11.75 3.5H3.25C2.55964 3.5 2 4.05964 2 4.75C2 5.44036 2.55964 6 3.25 6H11.75C12.4404 6 13 5.44036 13 4.75C13 4.05964 12.4404 3.5 11.75 3.5Z" />
      <path fill="currentColor" d="M4.25 3.5C3.55964 3.5 3 4.05964 3 4.75C3 5.44036 3.55964 6 4.25 6H5.25C5.94036 6 6.5 5.44036 6.5 4.75C6.5 4.05964 5.94036 3.5 5.25 3.5H4.25Z" />
      <path fill="currentColor" fillRule="evenodd" d="M3.25 8.5C1.73122 8.5 0.5 9.73122 0.5 11.25C0.5 12.7688 1.73122 14 3.25 14H11.75C13.2688 14 14.5 12.7688 14.5 11.25C14.5 9.73122 13.2688 8.5 11.75 8.5H3.25ZM12.75 11.25C12.75 11.9404 12.1904 12.5 11.5 12.5C10.8096 12.5 10.25 11.9404 10.25 11.25C10.25 10.5596 10.8096 10 11.5 10C12.1904 10 12.75 10.5596 12.75 11.25Z" />
    </svg>
  );
}

function Speaker({ color }) {
  return (
    <svg width="16" height="13" viewBox="0 0 16 13" aria-hidden>
      <path fill={color} d="M1.4 4.2h2.1L6.8 1.6c.4-.3 1 .0 1 .5v8.8c0 .5-.6.8-1 .5L3.5 8.8H1.4C1 8.8.7 8.5.7 8.1V4.9c0-.4.3-.7.7-.7z" />
      <path fill="none" stroke={color} strokeWidth="1.2" d="M10.2 4.2c.9.7 1.4 1.7 1.4 2.8s-.5 2.1-1.4 2.8" />
      <path fill="none" stroke={color} strokeWidth="1.2" d="M12.4 2.4c1.5 1.2 2.4 3 2.4 4.6s-.9 3.4-2.4 4.6" />
    </svg>
  );
}

export function MacMenuBar({ app = "Finder", phase = "morning", extraOpen = false }) {
  const ink = "rgba(255,255,255,0.96)";
  const menus = app === "Keep"
    ? ["Keep", "Edit", "View", "Window", "Help"]
    : ["Finder", "File", "Edit", "View", "Go", "Window", "Help"];
  return (
    <div
      style={{
        ...ABS,
        left: 0,
        right: 0,
        top: 0,
        height: MENU_H,
        zIndex: 44,
        display: "flex",
        alignItems: "center",
        padding: `0 ${RIGHT_PAD}px 0 8px`,
        fontFamily: "-apple-system, SF Pro Text, Inter, system-ui, sans-serif",
        fontSize: 14,
        fontWeight: 600,
        color: ink,
        letterSpacing: "-0.01em",
        background: "linear-gradient(to bottom, rgba(0,0,0,0.22), rgba(0,0,0,0))",
        textShadow: "0 1px 2px rgba(0,0,0,0.35)",
      }}
    >
      <span style={{ width: 36, height: MENU_H, display: "flex", alignItems: "center", justifyContent: "center" }}>
        <AppleLogo color={ink} />
      </span>
      {menus.map((m, i) => (
        <span key={m} style={{ marginRight: 1, padding: "3px 10px", fontWeight: i === 0 ? 700 : 600 }}>{m}</span>
      ))}
      <span style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: GAP, fontSize: 14, fontWeight: 600 }}>
        <span
          style={{
            width: KEEP_HIT,
            height: KEEP_HIT,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            borderRadius: 6,
            background: extraOpen ? "rgba(255,255,255,0.18)" : "transparent",
            flexShrink: 0,
          }}
        >
          <img
            src="../assets/macos/icons/keep.png"
            alt=""
            width={22}
            height={22}
            draggable={false}
            style={{ display: "block", width: 22, height: 22, objectFit: "contain" }}
          />
        </span>
        <Speaker color={ink} />
        <Battery color={ink} />
        <Wifi color={ink} />
        <ControlCenter color={ink} />
        <span style={{ width: CLOCK_W, textAlign: "right", whiteSpace: "pre", flexShrink: 0 }}>Mon, Sep 11  9:41 AM</span>
      </span>
    </div>
  );
}

function DockIcon({ src, open }) {
  return (
    <div style={{ position: "relative", width: DOCK_ICON, height: DOCK_ICON + 5, display: "flex", flexDirection: "column", alignItems: "center", flexShrink: 0 }}>
      <img
        src={src}
        alt=""
        width={DOCK_ICON}
        height={DOCK_ICON}
        draggable={false}
        style={{
          display: "block",
          width: DOCK_ICON,
          height: DOCK_ICON,
          objectFit: "cover",
          borderRadius: 14,
          boxShadow: "0 3px 10px rgba(0,0,0,0.28)",
        }}
      />
      {open ? (
        <div
          style={{
            position: "absolute",
            bottom: 0,
            width: 4,
            height: 4,
            borderRadius: 99,
            background: "rgba(255,255,255,0.92)",
            boxShadow: "0 0 4px rgba(255,255,255,0.55)",
          }}
        />
      ) : null}
    </div>
  );
}

export function MacDock({ night = false, keepOpen = false }) {
  const I = "../assets/macos/icons";
  const apps = [
    "finder", "keep", "messages", "mail", "maps", "photos", "facetime",
    "contacts", "calendar", "reminders", "notes", "appstore", "settings", "safari",
  ];
  const rim = night
    ? "inset 0 1.5px 0 0 rgba(255,255,255,0.08), inset 0 0 0 1.5px rgba(128,128,128,0.22), 0 18px 44px -12px rgba(0,0,0,0.45)"
    : "inset 0 1px 0 0 rgba(255,255,255,0.14), inset 0 0 0 1.5px rgba(255,255,255,0.22), 0 16px 40px -10px rgba(0,0,0,0.22)";
  return (
    <div
      style={{
        ...ABS,
        left: "50%",
        bottom: 4,
        transform: "translateX(-50%)",
        zIndex: 40,
        display: "flex",
        alignItems: "flex-end",
        justifyContent: "center",
        gap: 6,
        padding: "3px 14px 6px",
        borderRadius: 20,
        background: night ? "rgba(22,24,32,0.42)" : "rgba(245,245,247,0.28)",
        boxShadow: rim,
        backdropFilter: "blur(28px) saturate(1.7)",
        WebkitBackdropFilter: "blur(28px) saturate(1.7)",
      }}
    >
      {apps.map((name) => (
        <DockIcon
          key={name}
          src={`${I}/${name}.png`}
          open={name === "finder" || (name === "keep" && keepOpen)}
        />
      ))}
      <div
        style={{
          height: DOCK_ICON + 5,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          padding: "0 10px",
          flexShrink: 0,
        }}
      >
        <div
          style={{
            width: 1,
            height: Math.round(DOCK_ICON * 0.58),
            borderRadius: 99,
            background: night ? "rgba(255,255,255,0.34)" : "rgba(28,36,48,0.22)",
          }}
        />
      </div>
      <DockIcon src={`${I}/trash.png`} />
    </div>
  );
}
