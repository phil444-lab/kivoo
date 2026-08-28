import { Request, Response, NextFunction } from 'express';
import prisma from '../../lib/prisma.js';
import { NotFoundError, ValidationError } from '../../utils/ApiError.js';

/* ============================== CATÃ‰GORIES ============================== */

/**
 * GET /api/admin/categories â€” arbre complet avec compteurs
 */
export const getAdminCategories = async (
  _req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const categories = await prisma.category.findMany({
      where: { parentCategoryId: null },
      include: {
        subcategories: {
          include: { _count: { select: { items: true } } },
          orderBy: { name: 'asc' },
        },
        _count: { select: { items: true } },
      },
      orderBy: { name: 'asc' },
    });

    res.status(200).json({ success: true, data: categories });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/admin/categories  { name, parentCategoryId?, isActive? }
 */
export const createAdminCategory = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { name, parentCategoryId, isActive } = req.body as {
      name?: string;
      parentCategoryId?: string | null;
      isActive?: boolean;
    };

    if (!name || name.trim() === '') {
      throw new ValidationError('Le nom de la catÃ©gorie est requis');
    }

    const trimmed = name.trim();
    const existing = await prisma.category.findUnique({ where: { name: trimmed } });
    if (existing) {
      throw new ValidationError(`La catÃ©gorie "${trimmed}" existe dÃ©jÃ `);
    }

    if (parentCategoryId) {
      const parent = await prisma.category.findUnique({ where: { id: parentCategoryId } });
      if (!parent) {
        throw new NotFoundError('CatÃ©gorie parente');
      }
      // EmpÃªcher plus de 2 niveaux de profondeur
      if (parent.parentCategoryId) {
        throw new ValidationError(
          'Une sous-catÃ©gorie ne peut pas avoir sa propre sous-catÃ©gorie (2 niveaux max)'
        );
      }
    }

    const category = await prisma.category.create({
      data: {
        name: trimmed,
        parentCategoryId: parentCategoryId || null,
        isActive: isActive ?? true,
      },
      include: { _count: { select: { items: true } } },
    });

    res.status(201).json({
      success: true,
      message: 'CatÃ©gorie crÃ©Ã©e',
      data: category,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/admin/categories/:id  { name?, isActive?, parentCategoryId? }
 */
export const updateAdminCategory = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { name, isActive, parentCategoryId } = req.body as {
      name?: string;
      isActive?: boolean;
      parentCategoryId?: string | null;
    };

    const category = await prisma.category.findUnique({
      where: { id: req.params.id as string },
      include: { subcategories: { select: { id: true } } },
    });
    if (!category) {
      throw new NotFoundError('CatÃ©gorie');
    }

    const data: any = {};
    if (name !== undefined) {
      const trimmed = name.trim();
      if (trimmed === '') throw new ValidationError('Le nom ne peut pas Ãªtre vide');
      const existing = await prisma.category.findUnique({ where: { name: trimmed } });
      if (existing && existing.id !== category.id) {
        throw new ValidationError(`La catÃ©gorie "${trimmed}" existe dÃ©jÃ `);
      }
      data.name = trimmed;
    }
    if (typeof isActive === 'boolean') {
      data.isActive = isActive;
    }
    if (parentCategoryId !== undefined) {
      if (parentCategoryId === category.id) {
        throw new ValidationError('Une catÃ©gorie ne peut pas Ãªtre sa propre parente');
      }
      if (category.parentCategoryId === null && category.subcategories.length > 0) {
        throw new ValidationError(
          'Impossible de transformer une catÃ©gorie parente en sous-catÃ©gorie tant qu\'elle a des sous-catÃ©gories'
        );
      }
      data.parentCategoryId = parentCategoryId;
    }

    const updated = await prisma.category.update({
      where: { id: category.id },
      data,
      include: { _count: { select: { items: true } } },
    });

    res.status(200).json({
      success: true,
      message: 'CatÃ©gorie mise Ã  jour',
      data: updated,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/admin/categories/:id â€” bloquÃ© si des annonces y sont liÃ©es
 */
export const deleteAdminCategory = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const category = await prisma.category.findUnique({
      where: { id: req.params.id as string },
      include: {
        _count: { select: { items: true, subItems: true } },
        subcategories: { select: { id: true } },
      },
    });
    if (!category) {
      throw new NotFoundError('CatÃ©gorie');
    }

    const itemCount = category._count.items + category._count.subItems;
    if (itemCount > 0) {
      throw new ValidationError(
        `Impossible de supprimer : ${itemCount} annonce(s) liÃ©e(s). DÃ©sactivez la catÃ©gorie plutÃ´t que de la supprimer.`
      );
    }

    // Supprimer les sous-catÃ©gories vides d'abord
    await prisma.category.deleteMany({
      where: { parentCategoryId: category.id },
    });
    await prisma.category.delete({ where: { id: category.id } });

    res.status(200).json({
      success: true,
      message: 'CatÃ©gorie supprimÃ©e',
    });
  } catch (error) {
    next(error);
  }
};

/* ============================== ZONES (BÃ‰NIN) ============================== */

/**
 * GET /api/admin/locations/tree â€” arbre pays > dÃ©partements > villes > quartiers
 */
export const getAdminLocationTree = async (
  _req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const countries = await prisma.country.findMany({
      include: {
        departments: {
          include: {
            cities: {
              include: {
                districts: {
                  include: { _count: { select: { items: true } } },
                  orderBy: { name: 'asc' },
                },
                _count: { select: { items: true, districts: true } },
              },
              orderBy: { name: 'asc' },
            },
            _count: { select: { items: true, cities: true } },
          },
          orderBy: { name: 'asc' },
        },
      },
      orderBy: { name: 'asc' },
    });

    res.status(200).json({ success: true, data: countries });
  } catch (error) {
    next(error);
  }
};

const ZONES = {
  departments: {
    model: 'department' as const,
    label: 'DÃ©partement',
    parentField: 'countryId' as const,
    parentModel: 'country' as const,
  },
  cities: {
    model: 'city' as const,
    label: 'Ville',
    parentField: 'departmentId' as const,
    parentModel: 'department' as const,
  },
  districts: {
    model: 'district' as const,
    label: 'Quartier',
    parentField: 'cityId' as const,
    parentModel: 'city' as const,
  },
};

/**
 * GÃ©nÃ¨re les 3 handlers CRUD pour une zone (departments / cities / districts)
 */
const createZoneHandlers = (zoneKey: keyof typeof ZONES) => {
  const config = ZONES[zoneKey];

  const create = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { name } = req.body as { name?: string };
      const parentId = req.body[config.parentField] as string | undefined;

      if (!name || name.trim() === '') {
        throw new ValidationError(`Le nom du ${config.label.toLowerCase()} est requis`);
      }
      if (!parentId) {
        throw new ValidationError(`Le champ "${config.parentField}" est requis`);
      }

      const parent = await (prisma as any)[config.parentModel].findUnique({
        where: { id: parentId },
      });
      if (!parent) {
        throw new NotFoundError(config.parentField);
      }

      const created = await (prisma as any)[config.model].create({
        data: {
          name: name.trim(),
          [config.parentField]: parentId,
          isActive: true,
        },
      });

      res.status(201).json({
        success: true,
        message: `${config.label} crÃ©Ã©`,
        data: created,
      });
    } catch (error) {
      next(error);
    }
  };

  const update = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { name, isActive } = req.body as { name?: string; isActive?: boolean };
      const data: any = {};
      if (name !== undefined) {
        if (name.trim() === '') throw new ValidationError('Le nom ne peut pas Ãªtre vide');
        data.name = name.trim();
      }
      if (typeof isActive === 'boolean') data.isActive = isActive;

      if (Object.keys(data).length === 0) {
        throw new ValidationError('Aucun champ Ã  mettre Ã  jour');
      }

      const existing = await (prisma as any)[config.model].findUnique({
        where: { id: req.params.id as string },
      });
      if (!existing) {
        throw new NotFoundError(config.label);
      }

      const updated = await (prisma as any)[config.model].update({
        where: { id: existing.id },
        data,
      });

      res.status(200).json({
        success: true,
        message: `${config.label} mis Ã  jour`,
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  };

  const remove = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const existing = await (prisma as any)[config.model].findUnique({
        where: { id: req.params.id as string },
        include: { _count: { select: { items: true } } },
      });
      if (!existing) {
        throw new NotFoundError(config.label);
      }

      // VÃ©rifier les enfants selon la zone
      if (config.model === 'department') {
        const cityCount = await prisma.city.count({ where: { departmentId: existing.id } });
        if (cityCount > 0) {
          throw new ValidationError(
            `Impossible de supprimer : ${cityCount} ville(s) rattachÃ©e(s)`
          );
        }
      }
      if (config.model === 'city') {
        const districtCount = await prisma.district.count({ where: { cityId: existing.id } });
        if (districtCount > 0) {
          throw new ValidationError(
            `Impossible de supprimer : ${districtCount} quartier(s) rattachÃ©(s)`
          );
        }
      }
      if (existing._count.items > 0) {
        throw new ValidationError(
          `Impossible de supprimer : ${existing._count.items} annonce(s) liÃ©e(s). DÃ©sactivez plutÃ´t.`
        );
      }

      await (prisma as any)[config.model].delete({ where: { id: existing.id } });

      res.status(200).json({
        success: true,
        message: `${config.label} supprimÃ©`,
      });
    } catch (error) {
      next(error);
    }
  };

  return { create, update, remove };
};

const departmentHandlers = createZoneHandlers('departments');
const cityHandlers = createZoneHandlers('cities');
const districtHandlers = createZoneHandlers('districts');

export const createAdminDepartment = departmentHandlers.create;
export const updateAdminDepartment = departmentHandlers.update;
export const deleteAdminDepartment = departmentHandlers.remove;

export const createAdminCity = cityHandlers.create;
export const updateAdminCity = cityHandlers.update;
export const deleteAdminCity = cityHandlers.remove;

export const createAdminDistrict = districtHandlers.create;
export const updateAdminDistrict = districtHandlers.update;
export const deleteAdminDistrict = districtHandlers.remove;

/* ============================== OFFRES SPONSORISÃ‰ES ============================== */

/**
 * GET /api/admin/featured-options â€” toutes les offres (actives ou non) + compteurs
 */
export const getAdminFeaturedOptions = async (
  _req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const options = await prisma.featuredOption.findMany({
      include: { _count: { select: { items: true } } },
      orderBy: { order: 'asc' },
    });

    res.status(200).json({ success: true, data: options });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/admin/featured-options
 */
export const createAdminFeaturedOption = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { title, subtitle, icon, borderColor, darkBg, lightBg, isActive, order } =
      req.body as {
        title?: string;
        subtitle?: string;
        icon?: string;
        borderColor?: string;
        darkBg?: string;
        lightBg?: string;
        isActive?: boolean;
        order?: number;
      };

    if (!title || title.trim() === '') {
      throw new ValidationError('Le titre est requis');
    }
    if (!subtitle || subtitle.trim() === '') {
      throw new ValidationError('Le sous-titre est requis');
    }

    const hexRegex = /^#([0-9a-fA-F]{6})$/;
    for (const [field, value] of Object.entries({ borderColor, darkBg, lightBg })) {
      if (value && !hexRegex.test(value)) {
        throw new ValidationError(`${field} doit Ãªtre une couleur hexadÃ©cimale (#RRGGBB)`);
      }
    }

    const created = await prisma.featuredOption.create({
      data: {
        title: title.trim(),
        subtitle: subtitle.trim(),
        icon: icon || 'star',
        borderColor: borderColor || '#2563EB',
        darkBg: darkBg || '#1d232a',
        lightBg: lightBg || '#ffffff',
        isActive: isActive ?? true,
        order: order ?? 0,
      },
    });

    res.status(201).json({
      success: true,
      message: 'Offre sponsorisÃ©e crÃ©Ã©e',
      data: created,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PATCH /api/admin/featured-options/:id
 */
export const updateAdminFeaturedOption = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { title, subtitle, icon, borderColor, darkBg, lightBg, isActive, order } =
      req.body as Record<string, any>;

    const existing = await prisma.featuredOption.findUnique({
      where: { id: req.params.id as string },
    });
    if (!existing) {
      throw new NotFoundError('Offre sponsorisÃ©e');
    }

    const data: any = {};
    if (title !== undefined) {
      if (title.trim() === '') throw new ValidationError('Le titre ne peut pas Ãªtre vide');
      data.title = title.trim();
    }
    if (subtitle !== undefined) {
      if (subtitle.trim() === '') throw new ValidationError('Le sous-titre ne peut pas Ãªtre vide');
      data.subtitle = subtitle.trim();
    }
    if (icon !== undefined) data.icon = icon;
    if (borderColor !== undefined) data.borderColor = borderColor;
    if (darkBg !== undefined) data.darkBg = darkBg;
    if (lightBg !== undefined) data.lightBg = lightBg;
    if (typeof isActive === 'boolean') data.isActive = isActive;
    if (order !== undefined) data.order = parseInt(String(order), 10) || 0;

    if (Object.keys(data).length === 0) {
      throw new ValidationError('Aucun champ Ã  mettre Ã  jour');
    }

    const updated = await prisma.featuredOption.update({
      where: { id: existing.id },
      data,
    });

    res.status(200).json({
      success: true,
      message: 'Offre sponsorisÃ©e mise Ã  jour',
      data: updated,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/admin/featured-options/:id â€” bloquÃ© si des annonces y sont rattachÃ©es
 */
export const deleteAdminFeaturedOption = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const existing = await prisma.featuredOption.findUnique({
      where: { id: req.params.id as string },
      include: { _count: { select: { items: true } } },
    });
    if (!existing) {
      throw new NotFoundError('Offre sponsorisÃ©e');
    }

    if (existing._count.items > 0) {
      throw new ValidationError(
        `Impossible de supprimer : ${existing._count.items} annonce(s) rattachÃ©e(s). DÃ©sactivez l'offre plutÃ´t.`
      );
    }

    await prisma.featuredOption.delete({ where: { id: existing.id } });

    res.status(200).json({
      success: true,
      message: 'Offre sponsorisÃ©e supprimÃ©e',
    });
  } catch (error) {
    next(error);
  }
};



