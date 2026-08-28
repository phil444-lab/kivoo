export interface Pagination {
  currentPage: number;
  totalPages: number;
  totalItems: number;
  hasNext: boolean;
  hasPrev: boolean;
}

export interface AdminUser {
  id: string;
  name: string;
  email: string;
  phone: string;
  photo: string | null;
  location: unknown;
  verified: boolean;
  rating: number;
  ratingCount: number;
  joinedAt: string;
  lastLogin: string | null;
  isActive: boolean;
  role: string;
  _count?: {
    items: number;
    favorites: number;
    reports?: number;
    reportedIn?: number;
  };
}

export interface ItemCategory {
  id: string;
  name: string;
}

export interface ItemLocation {
  id: string;
  name: string;
}

export interface AdminItem {
  id: string;
  title: string;
  description: string;
  price: number;
  priceType: 'fixed' | 'negotiable' | 'rent' | 'auction';
  condition: string;
  images: unknown;
  status: 'active' | 'sold' | 'expired' | 'pending';
  featured: boolean;
  featuredUntil: string | null;
  boostLevel: number;
  boostUntil: string | null;
  views: number;
  likes: number;
  createdAt: string;
  updatedAt: string;
  expiresAt: string;
  seller: Pick<AdminUser, 'id' | 'name' | 'email' | 'phone' | 'photo' | 'verified' | 'isActive' | 'rating'>;
  category: ItemCategory | null;
  subcategory: ItemCategory | null;
  city: ItemLocation | null;
  department: ItemLocation | null;
  district: ItemLocation | null;
  feature: { id: string; title: string; icon: string; borderColor: string } | null;
  _count: { favorites: number; reports: number };
  reports?: AdminReport[];
}

export interface AdminReport {
  id: string;
  reporterId: string;
  reportedItemId: string;
  reportedUserId: string;
  reason: string;
  description: string | null;
  status: 'pending' | 'reviewed' | 'resolved' | 'dismissed';
  createdAt: string;
  reviewedAt: string | null;
  reporter: Pick<AdminUser, 'id' | 'name' | 'email' | 'phone' | 'photo'>;
  reportedUser: Pick<AdminUser, 'id' | 'name' | 'email' | 'phone' | 'photo' | 'isActive'>;
  reportedItem: AdminItem;
  reviewedBy?: { id: string; name: string } | null;
}

export interface AdminCategory {
  id: string;
  name: string;
  isActive: boolean;
  parentCategoryId: string | null;
  createdAt: string;
  subcategories?: AdminCategory[];
  _count?: { items: number };
}

export interface AdminSession {
  id: string;
  deviceInfo: string | null;
  ipAddress: string | null;
  createdAt: string;
  expiresAt: string;
}

export interface AdminUserDetail {
  user: AdminUser;
  items: AdminItem[];
  reviewsReceived: {
    id: string;
    rating: number;
    comment: string | null;
    createdAt: string;
    reviewer: Pick<AdminUser, 'id' | 'name' | 'photo'>;
    item: { id: string; title: string } | null;
  }[];
  activeSessions: AdminSession[];
}

export interface AdminFeaturedOption {
  id: string;
  title: string;
  subtitle: string;
  icon: string;
  borderColor: string;
  darkBg: string;
  lightBg: string;
  isActive: boolean;
  order: number;
  createdAt: string;
  _count?: { items: number };
}

export interface AdminCountry {
  id: string;
  name: string;
  code: string;
  isActive: boolean;
  departments: {
    id: string;
    name: string;
    isActive: boolean;
    cities: {
      id: string;
      name: string;
      isActive: boolean;
      districts: { id: string; name: string; isActive: boolean; _count: { items: number } }[];
      _count: { items: number; districts: number };
    }[];
    _count: { items: number; cities: number };
  }[];
}

export interface Stats {
  users: { total: number; newLast30d: number; active: number; verified: number; banned: number };
  items: { total: number; active: number; pending: number; sold: number; expired: number; featured: number };
  reports: { total: number; pending: number; reviewed: number; resolved: number; dismissed: number };
  activeSessions: number;
}

export interface Analytics {
  timeline: { date: string; label: string; signups: number; items: number }[];
  byCity: { city: string; count: number }[];
  days: number;
}

export interface NotificationRecord {
  id: string;
  title: string;
  message: string;
  type: string;
  read: boolean;
  createdAt: string;
  user: Pick<AdminUser, 'id' | 'name' | 'photo'>;
}
