export class ApiError extends Error {
  statusCode: number;
  isOperational: boolean;

  constructor(statusCode: number, message: string) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Object.setPrototypeOf(this, ApiError.prototype);
  }
}

export class NotFoundError extends ApiError {
  constructor(resource: string = 'Ressource') {
    super(404, `${resource} introuvable`);
  }
}

export class UnauthorizedError extends ApiError {
  constructor(message: string = 'Accès non autorisé') {
    super(401, message);
  }
}

export class ForbiddenError extends ApiError {
  constructor(message: string = 'Accès refusé') {
    super(403, message);
  }
}

export class ValidationError extends ApiError {
  constructor(message: string = 'Erreur de validation') {
    super(400, message);
  }
}