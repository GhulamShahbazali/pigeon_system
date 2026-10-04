import { DomainError } from '../../shared/errors/domain-error';

export class MessageRequestPendingError extends DomainError {
  readonly code = 'message_request_pending';
  readonly httpStatus = 422;
  constructor() {
    super('You can send only one message until they accept your request');
  }
}
