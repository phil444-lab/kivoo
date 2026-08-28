import { Request, Response, NextFunction } from 'express';
import prisma from '../../lib/prisma.js';

const USER_SELECT = {
  id: true,
  name: true,
  email: true,
  phone: true,
  photo: true,
  verified: true,
  isActive: true,
  role: true,
  rating: true,
  ratingCount: true,
  joinedAt: true,
  lastLogin: true,
};

/**
 * GET /api/admin/stats
 * KPIs globaux du dashboard
 */
export const getAdminStats = async (
  _req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const [
      totalUsers,
      newUsers30d,
      activeUsers,
      verifiedUsers,
      totalItems,
      activeItems,
      pendingItems,
      soldItems,
      expiredItems,
      featuredItems,
      pendingReports,
      reviewedReports,
      resolvedReports,
      dismissedReports,
      activeSessions,
    ] = await Promise.all([
      prisma.user.count(),
      prisma.user.count({ where: { joinedAt: { gte: thirtyDaysAgo } } }),
      prisma.user.count({ where: { isActive: true } }),
      prisma.user.count({ where: { verified: true } }),
      prisma.item.count(),
      prisma.item.count({ where: { status: 'active' } }),
      prisma.item.count({ where: { status: 'pending' } }),
      prisma.item.count({ where: { status: 'sold' } }),
      prisma.item.count({ where: { status: 'expired' } }),
      prisma.item.count({ where: { featured: true } }),
      prisma.report.count({ where: { status: 'pending' } }),
      prisma.report.count({ where: { status: 'reviewed' } }),
      prisma.report.count({ where: { status: 'resolved' } }),
      prisma.report.count({ where: { status: 'dismissed' } }),
      prisma.session.count({ where: { isActive: true, expiresAt: { gt: new Date() } } }),
    ]);

    res.status(200).json({
      success: true,
      data: {
        users: {
          total: totalUsers,
          newLast30d: newUsers30d,
          active: activeUsers,
          verified: verifiedUsers,
          banned: totalUsers - activeUsers,
        },
        items: {
          total: totalItems,
          active: activeItems,
          pending: pendingItems,
          sold: soldItems,
          expired: expiredItems,
          featured: featuredItems,
        },
        reports: {
          total: pendingReports + reviewedReports + resolvedReports + dismissedReports,
          pending: pendingReports,
          reviewed: reviewedReports,
          resolved: resolvedReports,
          dismissed: dismissedReports,
        },
        activeSessions,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/admin/analytics?days=30
 * Timeline inscriptions/annonces + répartition par ville
 */
export const getAdminAnalytics = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const days = Math.min(parseInt(req.query.days as string, 10) || 30, 365);
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    startDate.setHours(0, 0, 0, 0);

    const [users, items] = await Promise.all([
      prisma.user.findMany({
        where: { joinedAt: { gte: startDate } },
        select: { joinedAt: true },
      }),
      prisma.item.findMany({
        where: { createdAt: { gte: startDate } },
        select: { createdAt: true, cityId: true, city: { select: { name: true } } },
      }),
    ]);

    // Construire la timeline jour par jour
    const timeline: { date: string; label: string; signups: number; items: number }[] = [];
    for (let i = 0; i < days; i++) {
      const d = new Date(startDate);
      d.setDate(d.getDate() + i);
      const key = d.toISOString().slice(0, 10);
      timeline.push({
        date: key,
        label: d.toLocaleDateString('fr-FR', { day: '2-digit', month: 'short' }),
        signups: 0,
        items: 0,
      });
    }
    const byDate = new Map(timeline.map((t) => [t.date, t]));

    for (const u of users) {
      const key = u.joinedAt.toISOString().slice(0, 10);
      const entry = byDate.get(key);
      if (entry) entry.signups += 1;
    }
    for (const it of items) {
      const key = it.createdAt.toISOString().slice(0, 10);
      const entry = byDate.get(key);
      if (entry) entry.items += 1;
    }

    // Répartition par ville
    const cityMap = new Map<string, number>();
    for (const it of items) {
      const cityName = it.city?.name || 'Non renseignée';
      cityMap.set(cityName, (cityMap.get(cityName) || 0) + 1);
    }
    const byCity = Array.from(cityMap.entries())
      .map(([city, count]) => ({ city, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 10);

    res.status(200).json({
      success: true,
      data: { timeline, byCity, days },
    });
  } catch (error) {
    next(error);
  }
};

export { USER_SELECT };
