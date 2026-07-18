import { useState } from "react";
import {
  Search,
  ChevronDown,
  Home,
  Plus,
  MessageSquare,
  User,
  Grid3X3,
  List,
  MapPin,
  Bookmark,
  Tag,
  Bell,
  CheckCircle2,
  Sun,
  Moon,
} from "lucide-react";

const FEATURE_CARDS = [
  {
    id: 1,
    title: "Premium Deals",
    subtitle: "Up to 60% off",
    emoji: "🎁",
    borderColor: "#4f8ef7",
    darkBg: "linear-gradient(145deg, #142035 0%, #0e1a2e 100%)",
    lightBg: "linear-gradient(145deg, #deeaff 0%, #c8daff 100%)",
  },
  {
    id: 2,
    title: "New Arrivals",
    subtitle: "Fresh today",
    emoji: "✨",
    borderColor: "#22c55e",
    darkBg: "linear-gradient(145deg, #0f2718 0%, #0a2014 100%)",
    lightBg: "linear-gradient(145deg, #dcfce7 0%, #c5f4d4 100%)",
  },
  {
    id: 3,
    title: "Top Brands",
    subtitle: "Verified sellers",
    emoji: "🏆",
    borderColor: "#f59e0b",
    darkBg: "linear-gradient(145deg, #241a06 0%, #1c1404 100%)",
    lightBg: "linear-gradient(145deg, #fef3c7 0%, #fde8a0 100%)",
  },
  {
    id: 4,
    title: "Flash Sales",
    subtitle: "Limited time",
    emoji: "⚡",
    borderColor: "#a855f7",
    darkBg: "linear-gradient(145deg, #1c0e34 0%, #160828 100%)",
    lightBg: "linear-gradient(145deg, #f3e8ff 0%, #e9d5ff 100%)",
  },
];

const CATEGORIES = [
  { id: 1, emoji: "🚗", label: "Vehicles", color: "#ff6b35" },
  { id: 2, emoji: "🏠", label: "Real Estate", color: "#4f8ef7" },
  { id: 3, emoji: "📱", label: "Phones", color: "#22c55e" },
  { id: 4, emoji: "💼", label: "Jobs", color: "#f59e0b" },
  { id: 5, emoji: "👗", label: "Fashion", color: "#ec4899" },
  { id: 6, emoji: "🛋️", label: "Furniture", color: "#06b6d4" },
  { id: 7, emoji: "🐾", label: "Pets", color: "#a855f7" },
  { id: 8, emoji: "🔧", label: "Services", color: "#ef4444" },
];

const TRENDING = [
  {
    id: 1,
    title: "iPhone 15 Pro Max — 256GB Natural Titanium",
    price: "₦950,000",
    location: "Lagos Island, Lagos",
    condition: "Brand New",
    time: "2 hrs ago",
    photo:
      "https://images.unsplash.com/photo-1696446702183-a6a6b8de3c5b?w=160&h=160&fit=crop&auto=format",
    verified: true,
  },
  {
    id: 2,
    title: "2021 Toyota Camry XSE V6 — Low Mileage",
    price: "₦14,500,000",
    location: "Ikeja GRA, Lagos",
    condition: "Foreign Used",
    time: "5 hrs ago",
    photo:
      "https://images.unsplash.com/photo-1625047509248-ec889cbff17f?w=160&h=160&fit=crop&auto=format",
    verified: true,
  },
  {
    id: 3,
    title: "3 Bedroom Apartment — Lekki Phase 1",
    price: "₦4,200,000/yr",
    location: "Lekki Phase 1, Lagos",
    condition: "For Rent",
    time: "1 day ago",
    photo:
      "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=160&h=160&fit=crop&auto=format",
    verified: false,
  },
  {
    id: 4,
    title: "Samsung Galaxy S24 Ultra — 512GB Titanium Black",
    price: "₦780,000",
    location: "Wuse II, Abuja",
    condition: "Slightly Used",
    time: "3 hrs ago",
    photo:
      "https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=160&h=160&fit=crop&auto=format",
    verified: true,
  },
  {
    id: 5,
    title: 'MacBook Pro 16" M3 Max — 36GB RAM, 1TB',
    price: "₦1,850,000",
    location: "Victoria Island, Lagos",
    condition: "Brand New",
    time: "6 hrs ago",
    photo:
      "https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=160&h=160&fit=crop&auto=format",
    verified: false,
  },
];

const LOCATIONS = ["Lagos", "Abuja", "Port Harcourt", "Kano", "Ibadan", "Enugu"];
const FILTERS = ["All", "Electronics", "Vehicles", "Real Estate", "Fashion"];

// ─── Theme tokens ──────────────────────────────────────────────────────────────
const DARK = {
  bg: "#12161a",
  card: "#1d232a",
  cardBorder: "rgba(255,255,255,0.05)",
  cardShadow: "0 2px 16px rgba(0,0,0,0.35)",
  surface: "#252d36",
  text: "#ffffff",
  textMuted: "#9ca3af",
  textFaint: "#4b5563",
  filterInactive: "#1d232a",
  filterInactiveBorder: "rgba(255,255,255,0.06)",
  filterInactiveText: "#9ca3af",
  navBg: "rgba(18,22,26,0.96)",
  navBorder: "rgba(255,255,255,0.08)",
  searchBarBg: "rgba(255,255,255,0.12)",
  searchBarBorder: "rgba(255,255,255,0.2)",
  locationBtnBg: "rgba(255,255,255,0.15)",
  divider: "rgba(255,255,255,0.2)",
  catBg: "linear-gradient(145deg, #232b34, #191f26)",
  catShadow: "4px 4px 12px rgba(0,0,0,0.55), -1px -1px 4px rgba(255,255,255,0.04), inset 0 1px 0 rgba(255,255,255,0.06)",
  catBorder: "rgba(255,255,255,0.05)",
  toggleBg: "#1d232a",
  toggleBorder: "rgba(255,255,255,0.05)",
  dropdownBg: "#1d232a",
  dropdownBorder: "rgba(255,255,255,0.08)",
};

const LIGHT = {
  bg: "#f0f2f5",
  card: "#ffffff",
  cardBorder: "rgba(0,0,0,0.07)",
  cardShadow: "0 2px 12px rgba(0,0,0,0.08)",
  surface: "#f5f6f8",
  text: "#111827",
  textMuted: "#6b7280",
  textFaint: "#9ca3af",
  filterInactive: "#ffffff",
  filterInactiveBorder: "rgba(0,0,0,0.08)",
  filterInactiveText: "#6b7280",
  navBg: "rgba(255,255,255,0.97)",
  navBorder: "rgba(0,0,0,0.08)",
  searchBarBg: "rgba(255,255,255,0.18)",
  searchBarBorder: "rgba(255,255,255,0.35)",
  locationBtnBg: "rgba(255,255,255,0.22)",
  divider: "rgba(255,255,255,0.35)",
  catBg: "linear-gradient(145deg, #ffffff, #f0f2f5)",
  catShadow: "3px 3px 8px rgba(0,0,0,0.1), -1px -1px 3px rgba(255,255,255,0.9), inset 0 1px 0 rgba(255,255,255,0.8)",
  catBorder: "rgba(0,0,0,0.06)",
  toggleBg: "#ffffff",
  toggleBorder: "rgba(0,0,0,0.06)",
  dropdownBg: "#ffffff",
  dropdownBorder: "rgba(0,0,0,0.08)",
};

export default function App() {
  const [isDark, setIsDark] = useState(true);
  const [activeTab, setActiveTab] = useState("home");
  const [viewMode, setViewMode] = useState<"list" | "grid">("list");
  const [selectedLocation, setSelectedLocation] = useState("Lagos");
  const [showLocationMenu, setShowLocationMenu] = useState(false);
  const [savedItems, setSavedItems] = useState<number[]>([]);
  const [activeFilter, setActiveFilter] = useState("All");

  const t = isDark ? DARK : LIGHT;

  const toggleSave = (id: number) => {
    setSavedItems((prev) =>
      prev.includes(id) ? prev.filter((i) => i !== id) : [...prev, id]
    );
  };

  return (
    <div
      className="min-h-screen mx-auto relative overflow-x-hidden"
      style={{
        background: t.bg,
        maxWidth: "430px",
        paddingBottom: "80px",
        fontFamily: "'Inter', sans-serif",
        transition: "background 0.3s ease",
      }}
    >
      {/* ── STATUS BAR ── */}
      <div
        className="flex items-center justify-between px-5 pt-3 pb-1.5 text-white"
        style={{ background: "#bc171a" }}
      >
        <span style={{ fontSize: "12px", fontWeight: 700 }}>9:41</span>
        <div className="flex items-center gap-2" style={{ fontSize: "11px", fontWeight: 600 }}>
          <span style={{ letterSpacing: "1px" }}>●●●●</span>
          <span>WiFi</span>
          <span>🔋</span>
        </div>
      </div>

      {/* ── HEADER ── */}
      <div style={{ background: "#bc171a" }} className="px-4 pt-2 pb-5">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2.5">
            <div
              className="w-8 h-8 rounded-xl flex items-center justify-center"
              style={{ background: "rgba(255,255,255,0.2)" }}
            >
              <Tag size={15} color="#fff" strokeWidth={2.5} />
            </div>
            <span style={{ color: "#fff", fontWeight: 800, fontSize: "18px", letterSpacing: "-0.3px" }}>
              Marketa
            </span>
          </div>
          <div className="flex items-center gap-3">
            {/* Theme toggle */}
            <button
              onClick={() => setIsDark(!isDark)}
              className="w-8 h-8 rounded-full flex items-center justify-center transition-all"
              style={{
                background: "rgba(255,255,255,0.18)",
                border: "1px solid rgba(255,255,255,0.25)",
              }}
              title={isDark ? "Switch to light mode" : "Switch to dark mode"}
            >
              {isDark ? (
                <Sun size={15} color="#fff" strokeWidth={2} />
              ) : (
                <Moon size={15} color="#fff" strokeWidth={2} />
              )}
            </button>
            <button className="relative">
              <Bell size={20} color="rgba(255,255,255,0.85)" />
              <span
                className="absolute -top-1 -right-1 w-3.5 h-3.5 rounded-full flex items-center justify-center text-white"
                style={{ background: "#12161a", fontSize: "8px", fontWeight: 700 }}
              >
                2
              </span>
            </button>
            <div
              className="w-8 h-8 rounded-full flex items-center justify-center"
              style={{ background: "rgba(255,255,255,0.2)" }}
            >
              <span style={{ color: "#fff", fontSize: "11px", fontWeight: 700 }}>AO</span>
            </div>
          </div>
        </div>

        {/* Dual search bar */}
        <div
          className="flex items-center gap-2 rounded-2xl p-1.5"
          style={{
            background: t.searchBarBg,
            border: `1px solid ${t.searchBarBorder}`,
            backdropFilter: "blur(12px)",
          }}
        >
          {/* Location dropdown */}
          <div className="relative flex-shrink-0">
            <button
              onClick={() => setShowLocationMenu(!showLocationMenu)}
              className="flex items-center gap-1.5 rounded-xl px-3 py-2"
              style={{ background: t.locationBtnBg }}
            >
              <MapPin size={11} color="rgba(255,255,255,0.85)" />
              <span style={{ color: "#fff", fontSize: "12px", fontWeight: 600, whiteSpace: "nowrap" }}>
                {selectedLocation}
              </span>
              <ChevronDown
                size={11}
                color="rgba(255,255,255,0.85)"
                style={{
                  transform: showLocationMenu ? "rotate(180deg)" : "rotate(0deg)",
                  transition: "transform 0.2s",
                }}
              />
            </button>
            {showLocationMenu && (
              <div
                className="absolute top-11 left-0 z-50 rounded-2xl overflow-hidden shadow-2xl"
                style={{
                  background: t.dropdownBg,
                  border: `1px solid ${t.dropdownBorder}`,
                  minWidth: "148px",
                  boxShadow: "0 16px 48px rgba(0,0,0,0.3)",
                  transition: "background 0.3s",
                }}
              >
                {LOCATIONS.map((loc) => (
                  <button
                    key={loc}
                    onClick={() => { setSelectedLocation(loc); setShowLocationMenu(false); }}
                    className="w-full text-left px-4 py-2.5 flex items-center gap-2 transition-colors"
                    style={{
                      color: loc === selectedLocation ? "#e42226" : t.text,
                      fontSize: "13px",
                      fontWeight: loc === selectedLocation ? 600 : 400,
                    }}
                    onMouseEnter={(e) =>
                      ((e.currentTarget as HTMLElement).style.background = isDark
                        ? "rgba(255,255,255,0.05)"
                        : "rgba(0,0,0,0.04)")
                    }
                    onMouseLeave={(e) =>
                      ((e.currentTarget as HTMLElement).style.background = "transparent")
                    }
                  >
                    <MapPin size={11} color={loc === selectedLocation ? "#e42226" : t.textMuted} />
                    {loc}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Divider */}
          <div style={{ width: "1px", height: "24px", background: t.divider }} />

          {/* Search input */}
          <div className="flex-1 flex items-center gap-2 px-1">
            <input
              type="text"
              placeholder="I am looking for..."
              className="flex-1 bg-transparent outline-none"
              style={{ color: "#fff", fontSize: "13px" }}
            />
            <button
              className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
              style={{
                background: "linear-gradient(135deg, #e42226, #bc171a)",
                boxShadow: "0 2px 8px rgba(228,34,38,0.5)",
              }}
            >
              <Search size={15} color="#fff" strokeWidth={2.5} />
            </button>
          </div>
        </div>
      </div>

      {/* ── FEATURE CARDS ── */}
      <div className="mt-5">
        <div className="flex items-center justify-between px-4 mb-3">
          <span style={{ color: t.text, fontWeight: 700, fontSize: "15px", transition: "color 0.3s" }}>Featured</span>
          <button style={{ color: "#e42226", fontSize: "12px", fontWeight: 600 }}>See all</button>
        </div>
        <div className="flex gap-3 overflow-x-auto px-4 pb-2" style={{ scrollbarWidth: "none" }}>
          {FEATURE_CARDS.map((card) => (
            <div
              key={card.id}
              className="flex-shrink-0 rounded-2xl p-4 relative overflow-hidden cursor-pointer"
              style={{
                width: "155px",
                background: isDark ? card.darkBg : card.lightBg,
                border: `1.5px solid ${card.borderColor}`,
                boxShadow: `0 6px 24px ${card.borderColor}28, inset 0 1px 0 ${isDark ? "rgba(255,255,255,0.07)" : "rgba(255,255,255,0.6)"}`,
                transition: "transform 0.15s, background 0.3s",
              }}
              onMouseEnter={(e) => ((e.currentTarget as HTMLElement).style.transform = "translateY(-2px)")}
              onMouseLeave={(e) => ((e.currentTarget as HTMLElement).style.transform = "translateY(0)")}
            >
              <div
                className="w-14 h-14 rounded-2xl flex items-center justify-center mb-3"
                style={{
                  background: `linear-gradient(145deg, ${card.borderColor}22, ${card.borderColor}0a)`,
                  boxShadow: isDark
                    ? `3px 3px 10px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.08)`
                    : `3px 3px 8px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.7)`,
                  border: `1px solid ${card.borderColor}40`,
                  fontSize: "28px",
                  filter: "drop-shadow(0 4px 8px rgba(0,0,0,0.3))",
                }}
              >
                {card.emoji}
              </div>
              <div style={{ color: isDark ? "#ffffff" : "#111827", fontWeight: 700, fontSize: "13px", lineHeight: 1.3 }}>
                {card.title}
              </div>
              <div style={{ color: card.borderColor, fontSize: "11px", fontWeight: 600, marginTop: "3px" }}>
                {card.subtitle}
              </div>
              <div
                className="absolute -bottom-5 -right-5 w-16 h-16 rounded-full blur-2xl"
                style={{ background: card.borderColor, opacity: 0.2 }}
              />
            </div>
          ))}
        </div>
      </div>

      {/* ── CATEGORY GRID ── */}
      <div className="px-4 mt-6">
        <div className="flex items-center justify-between mb-3">
          <span style={{ color: t.text, fontWeight: 700, fontSize: "15px", transition: "color 0.3s" }}>Categories</span>
          <button style={{ color: "#e42226", fontSize: "12px", fontWeight: 600 }}>All</button>
        </div>
        <div className="grid grid-cols-4 gap-3">
          {CATEGORIES.map((cat) => (
            <button
              key={cat.id}
              className="flex flex-col items-center gap-2"
              style={{ transition: "transform 0.15s" }}
              onMouseEnter={(e) => ((e.currentTarget as HTMLElement).style.transform = "scale(1.05)")}
              onMouseLeave={(e) => ((e.currentTarget as HTMLElement).style.transform = "scale(1)")}
            >
              <div
                className="w-full aspect-square rounded-2xl flex items-center justify-center relative overflow-hidden"
                style={{
                  background: t.catBg,
                  boxShadow: t.catShadow,
                  border: `1px solid ${t.catBorder}`,
                  transition: "background 0.3s, box-shadow 0.3s",
                }}
              >
                <span
                  style={{
                    fontSize: "1.65rem",
                    filter: "drop-shadow(0 4px 8px rgba(0,0,0,0.3))",
                  }}
                >
                  {cat.emoji}
                </span>
                <div
                  className="absolute bottom-0 left-1/2 -translate-x-1/2 w-10 h-5 rounded-full blur-xl"
                  style={{ background: cat.color, opacity: isDark ? 0.35 : 0.2 }}
                />
              </div>
              <span
                style={{
                  color: t.text,
                  fontSize: "11px",
                  fontWeight: 500,
                  textAlign: "center",
                  lineHeight: 1.2,
                  transition: "color 0.3s",
                }}
              >
                {cat.label}
              </span>
            </button>
          ))}
        </div>
      </div>

      {/* ── TRENDING ── */}
      <div className="px-4 mt-7">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <span style={{ color: t.text, fontWeight: 700, fontSize: "15px", transition: "color 0.3s" }}>
              Trending
            </span>
            <span
              className="px-2 py-0.5 rounded-full"
              style={{ background: "#e42226", color: "#fff", fontSize: "10px", fontWeight: 700 }}
            >
              🔥 HOT
            </span>
          </div>
          {/* View toggle */}
          <div
            className="flex items-center gap-0.5 rounded-xl p-1"
            style={{
              background: t.toggleBg,
              border: `1px solid ${t.toggleBorder}`,
              transition: "background 0.3s",
            }}
          >
            <button
              onClick={() => setViewMode("list")}
              className="p-1.5 rounded-lg transition-all"
              style={{
                background: viewMode === "list" ? "#e42226" : "transparent",
                boxShadow: viewMode === "list" ? "0 2px 8px rgba(228,34,38,0.4)" : "none",
              }}
            >
              <List size={14} color={viewMode === "list" ? "#fff" : t.textMuted} />
            </button>
            <button
              onClick={() => setViewMode("grid")}
              className="p-1.5 rounded-lg transition-all"
              style={{
                background: viewMode === "grid" ? "#e42226" : "transparent",
                boxShadow: viewMode === "grid" ? "0 2px 8px rgba(228,34,38,0.4)" : "none",
              }}
            >
              <Grid3X3 size={14} color={viewMode === "grid" ? "#fff" : t.textMuted} />
            </button>
          </div>
        </div>

        {/* Filter pills */}
        <div className="flex gap-2 overflow-x-auto pb-3" style={{ scrollbarWidth: "none" }}>
          {FILTERS.map((filter) => (
            <button
              key={filter}
              onClick={() => setActiveFilter(filter)}
              className="flex-shrink-0 rounded-full px-3.5 py-1.5 transition-all"
              style={{
                background: activeFilter === filter ? "#e42226" : t.filterInactive,
                color: activeFilter === filter ? "#fff" : t.filterInactiveText,
                fontSize: "12px",
                fontWeight: 600,
                border: activeFilter === filter ? "none" : `1px solid ${t.filterInactiveBorder}`,
                boxShadow: activeFilter === filter ? "0 2px 10px rgba(228,34,38,0.35)" : "none",
                transition: "background 0.2s, color 0.2s",
              }}
            >
              {filter}
            </button>
          ))}
        </div>

        {/* LIST VIEW */}
        {viewMode === "list" && (
          <div className="flex flex-col gap-3">
            {TRENDING.map((item) => (
              <div
                key={item.id}
                className="flex gap-3 rounded-2xl p-3 relative cursor-pointer"
                style={{
                  background: t.card,
                  border: `1px solid ${t.cardBorder}`,
                  boxShadow: t.cardShadow,
                  transition: "transform 0.15s, background 0.3s",
                }}
                onMouseEnter={(e) => ((e.currentTarget as HTMLElement).style.transform = "translateY(-1px)")}
                onMouseLeave={(e) => ((e.currentTarget as HTMLElement).style.transform = "translateY(0)")}
              >
                <div className="relative flex-shrink-0">
                  <div
                    className="w-[78px] h-[78px] rounded-xl overflow-hidden"
                    style={{ background: t.surface }}
                  >
                    <img src={item.photo} alt={item.title} className="w-full h-full object-cover" />
                  </div>
                  {item.verified && (
                    <div className="absolute -top-1.5 -right-1.5">
                      <CheckCircle2
                        size={16}
                        style={{ color: "#22c55e", background: t.card, borderRadius: "50%" }}
                      />
                    </div>
                  )}
                </div>

                <div className="flex-1 min-w-0 pr-5">
                  <div
                    className="font-bold leading-snug mb-1 line-clamp-2"
                    style={{ color: t.text, fontSize: "13px", transition: "color 0.3s" }}
                  >
                    {item.title}
                  </div>
                  <div className="font-extrabold mb-1.5" style={{ color: "#e42226", fontSize: "15px" }}>
                    {item.price}
                  </div>
                  <div className="flex items-center gap-1 mb-1.5">
                    <MapPin size={10} color={t.textMuted} />
                    <span style={{ color: t.textMuted, fontSize: "11px" }}>{item.location}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span
                      className="rounded-full px-2 py-0.5"
                      style={{
                        background: "rgba(228,34,38,0.12)",
                        color: "#ef7d7f",
                        fontSize: "10px",
                        fontWeight: 600,
                        border: "1px solid rgba(228,34,38,0.22)",
                      }}
                    >
                      {item.condition}
                    </span>
                    <span style={{ color: t.textFaint, fontSize: "10px" }}>{item.time}</span>
                  </div>
                </div>

                <button onClick={() => toggleSave(item.id)} className="absolute top-3 right-3">
                  <Bookmark
                    size={16}
                    color={savedItems.includes(item.id) ? "#e42226" : t.textFaint}
                    fill={savedItems.includes(item.id) ? "#e42226" : "none"}
                  />
                </button>
              </div>
            ))}
          </div>
        )}

        {/* GRID VIEW */}
        {viewMode === "grid" && (
          <div className="grid grid-cols-2 gap-3">
            {TRENDING.map((item) => (
              <div
                key={item.id}
                className="rounded-2xl overflow-hidden cursor-pointer"
                style={{
                  background: t.card,
                  border: `1px solid ${t.cardBorder}`,
                  boxShadow: t.cardShadow,
                  transition: "transform 0.15s, background 0.3s",
                }}
                onMouseEnter={(e) => ((e.currentTarget as HTMLElement).style.transform = "translateY(-2px)")}
                onMouseLeave={(e) => ((e.currentTarget as HTMLElement).style.transform = "translateY(0)")}
              >
                <div className="relative aspect-square" style={{ background: t.surface }}>
                  <img src={item.photo} alt={item.title} className="w-full h-full object-cover" />
                  <button
                    onClick={() => toggleSave(item.id)}
                    className="absolute top-2 right-2 w-7 h-7 rounded-full flex items-center justify-center"
                    style={{
                      background: isDark ? "rgba(18,22,26,0.82)" : "rgba(255,255,255,0.88)",
                      backdropFilter: "blur(4px)",
                    }}
                  >
                    <Bookmark
                      size={13}
                      color={savedItems.includes(item.id) ? "#e42226" : t.textMuted}
                      fill={savedItems.includes(item.id) ? "#e42226" : "none"}
                    />
                  </button>
                  {item.verified && (
                    <div className="absolute top-2 left-2">
                      <CheckCircle2
                        size={15}
                        style={{ color: "#22c55e", background: t.card, borderRadius: "50%" }}
                      />
                    </div>
                  )}
                </div>
                <div className="p-3">
                  <div
                    className="font-bold leading-snug mb-1 line-clamp-2"
                    style={{ color: t.text, fontSize: "12px", transition: "color 0.3s" }}
                  >
                    {item.title}
                  </div>
                  <div className="font-extrabold mb-0.5" style={{ color: "#e42226", fontSize: "14px" }}>
                    {item.price}
                  </div>
                  <div className="flex items-center gap-1">
                    <MapPin size={9} color={t.textMuted} />
                    <span className="truncate" style={{ color: t.textMuted, fontSize: "10px" }}>
                      {item.location}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* ── BOTTOM NAV ── */}
      <div
        className="fixed bottom-0 left-1/2 -translate-x-1/2 flex items-end justify-around pt-2 pb-3 px-1"
        style={{
          width: "100%",
          maxWidth: "430px",
          background: t.navBg,
          borderTop: `1px solid ${t.navBorder}`,
          backdropFilter: "blur(20px)",
          zIndex: 100,
          transition: "background 0.3s, border-color 0.3s",
        }}
      >
        {[
          { id: "home", Icon: Home, label: "Home" },
          { id: "saved", Icon: Bookmark, label: "Saved" },
        ].map(({ id, Icon, label }) => (
          <button
            key={id}
            onClick={() => setActiveTab(id)}
            className="flex flex-col items-center gap-1 min-w-[56px] relative"
          >
            {id === "saved" && savedItems.length > 0 && (
              <span
                className="absolute -top-0.5 right-2 w-4 h-4 rounded-full flex items-center justify-center text-white"
                style={{ background: "#e42226", fontSize: "9px", fontWeight: 700 }}
              >
                {savedItems.length}
              </span>
            )}
            <Icon
              size={22}
              color={activeTab === id ? "#ef7d7f" : t.textFaint}
              strokeWidth={activeTab === id ? 2.5 : 1.8}
              fill={activeTab === id && id === "saved" ? "#ef7d7f" : "none"}
            />
            <span
              style={{
                fontSize: "10px",
                fontWeight: 600,
                color: activeTab === id ? "#ef7d7f" : t.textFaint,
                transition: "color 0.3s",
              }}
            >
              {label}
            </span>
          </button>
        ))}

        {/* Sell FAB */}
        <button
          onClick={() => setActiveTab("sell")}
          className="flex flex-col items-center gap-1 -mt-4"
        >
          <div
            className="w-14 h-14 rounded-2xl flex items-center justify-center"
            style={{
              background: "linear-gradient(135deg, #e42226 0%, #bc171a 100%)",
              boxShadow: "0 6px 20px rgba(228,34,38,0.55), 0 2px 6px rgba(0,0,0,0.3)",
            }}
          >
            <Plus size={24} color="#fff" strokeWidth={2.5} />
          </div>
          <span style={{ fontSize: "10px", fontWeight: 700, color: "#ef7d7f" }}>Sell</span>
        </button>

        {[
          { id: "messages", Icon: MessageSquare, label: "Messages", badge: 3 },
          { id: "profile", Icon: User, label: "Profile" },
        ].map(({ id, Icon, label, badge }) => (
          <button
            key={id}
            onClick={() => setActiveTab(id)}
            className="flex flex-col items-center gap-1 min-w-[56px] relative"
          >
            {badge && (
              <span
                className="absolute -top-0.5 right-2 w-4 h-4 rounded-full flex items-center justify-center text-white"
                style={{ background: "#e42226", fontSize: "9px", fontWeight: 700 }}
              >
                {badge}
              </span>
            )}
            <Icon
              size={22}
              color={activeTab === id ? "#ef7d7f" : t.textFaint}
              strokeWidth={activeTab === id ? 2.5 : 1.8}
            />
            <span
              style={{
                fontSize: "10px",
                fontWeight: 600,
                color: activeTab === id ? "#ef7d7f" : t.textFaint,
                transition: "color 0.3s",
              }}
            >
              {label}
            </span>
          </button>
        ))}
      </div>
    </div>
  );
}
