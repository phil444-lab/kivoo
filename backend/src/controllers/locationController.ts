import { Request, Response, NextFunction } from 'express';
import prisma from '../lib/prisma.js';

export const getCountries = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const countries = await prisma.country.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    });

    res.status(200).json({
      success: true,
      data: countries,
    });
  } catch (error) {
    next(error);
  }
};

export const getDepartments = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const countryId = req.params.countryId as string;

    const departments = await prisma.department.findMany({
      where: {
        countryId,
        isActive: true,
      },
      orderBy: { name: 'asc' },
    });

    res.status(200).json({
      success: true,
      data: departments,
    });
  } catch (error) {
    next(error);
  }
};

export const getCities = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const departmentId = req.params.departmentId as string;

    const cities = await prisma.city.findMany({
      where: {
        departmentId,
        isActive: true,
      },
      orderBy: { name: 'asc' },
    });

    res.status(200).json({
      success: true,
      data: cities,
    });
  } catch (error) {
    next(error);
  }
};

export const getDistricts = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const cityId = req.params.cityId as string;

    const districts = await prisma.district.findMany({
      where: {
        cityId,
        isActive: true,
      },
      orderBy: { name: 'asc' },
    });

    res.status(200).json({
      success: true,
      data: districts,
    });
  } catch (error) {
    next(error);
  }
};

export const getAllLocations = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const countries = await prisma.country.findMany({
      where: { isActive: true },
      include: {
        departments: {
          where: { isActive: true },
          include: {
            cities: {
              where: { isActive: true },
              include: {
                districts: {
                  where: { isActive: true },
                  orderBy: { name: 'asc' },
                },
              },
              orderBy: { name: 'asc' },
            },
          },
          orderBy: { name: 'asc' },
        },
      },
      orderBy: { name: 'asc' },
    });

    res.status(200).json({
      success: true,
      data: countries,
    });
  } catch (error) {
    next(error);
  }
};