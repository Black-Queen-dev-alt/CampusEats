export class AppError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public code: string = 'ERROR',
    public details: unknown = null
  ) {
    super(message);
    Object.setPrototypeOf(this, new.target.prototype);
  }

  static badRequest(msg: string, details?: unknown) {
    return new AppError(400, msg, 'BAD_REQUEST', details);
  }
  static unauthorized(msg = 'Non authentifié') {
    return new AppError(401, msg, 'UNAUTHORIZED');
  }
  static forbidden(msg = 'Accès interdit') {
    return new AppError(403, msg, 'FORBIDDEN');
  }
  static notFound(msg = 'Ressource introuvable') {
    return new AppError(404, msg, 'NOT_FOUND');
  }
  static conflict(msg: string, code = 'CONFLICT') {
    return new AppError(409, msg, code);
  }
  static unprocessable(msg: string, details?: unknown) {
    return new AppError(422, msg, 'VALIDATION_ERROR', details);
  }
  static internal(msg = 'Erreur interne du serveur') {
    return new AppError(500, msg, 'INTERNAL_SERVER_ERROR');
  }
}
