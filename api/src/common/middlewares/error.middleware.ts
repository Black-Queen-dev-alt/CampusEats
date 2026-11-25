import { Request, Response, NextFunction } from 'express';
import { Error as MongooseError } from 'mongoose';
import { AppError } from '../errors/app-error';

export const errorHandler = (
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
) => {
  let appError: AppError;
  if (err instanceof AppError) {
    appError = err;
  } else if (isDuplicateKeyError(err)) {
    appError = AppError.conflict('Une ressource avec ces informations existe déjà.');
  } else if (err instanceof MongooseError.ValidationError) {
    appError = AppError.unprocessable(
      'Les données fournies ne respectent pas les règles métier.',
      Object.values(err.errors).map((issue) => ({
        field: issue.path,
        message: issue.message,
      })),
    );
  } else if (err instanceof MongooseError.CastError) {
    appError = AppError.badRequest('Un identifiant ou une valeur est invalide.', {
      field: err.path,
    });
  } else if (isMalformedJsonError(err)) {
    appError = AppError.badRequest('Le corps de la requête JSON est mal formé.');
  } else if (isPayloadTooLargeError(err)) {
    appError = new AppError(413, 'Le corps de la requête dépasse la taille maximale autorisée.', 'PAYLOAD_TOO_LARGE');
  } else {
    console.error('💥 Erreur non gérée :', err);
    appError = AppError.internal();
  }

  return res.status(appError.statusCode).json({
    success: false,
    error: {
      code: appError.code,
      message: appError.message,
      details: appError.details,
    },
  });
};

function isDuplicateKeyError(error: Error): error is Error & { code: number } {
  return 'code' in error && error.code === 11000;
}

function isMalformedJsonError(error: Error): boolean {
  return error instanceof SyntaxError && 'body' in error;
}

function isPayloadTooLargeError(error: Error): boolean {
  return 'type' in error && error.type === 'entity.too.large';
}
