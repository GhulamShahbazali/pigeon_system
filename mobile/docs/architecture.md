# PigeonFly Mobile — Architecture

> **Read `../AGENTS.md` first.** This document describes *how* the Flutter code is organised. Product decisions live in `../../docs/product/locked-decisions.md`; schema and API contracts live in `../../docs/technical/`. Realtime topology and events live in `../../docs/technical/performance-and-realtime.md`.
> **Pattern adapted from Talksy Mobile Architecture.**
> **Last updated:** 2026-10-03 · **Version:** 1.0

---

## Table of Contents

1. [Full Folder Tree](#full-folder-tree)
2. [Feature Internal Structure](#feature-internal-structure)
3. [Dependency Rule](#dependency-rule)
4. [Layer Responsibilities](#layer-responsibilities)
5. [Cross-Cutting Infrastructure](#cross-cutting-infrastructure)
6. [`Result<T>` — The Only Error Approach](#resultt--the-only-error-approach)
7. [`Failure` Hierarchy](#failure-hierarchy)
8. [Exception Types](#exception-types)
9. [`UseCase` Base Classes](#usecase-base-classes)
10. [`ApiClient` Pattern](#apiclient-pattern)
11. [`DataSource` Pattern](#datasource-pattern)
12. [Repository Implementation Pattern](#repository-implementation-pattern)
13. [Entity Pattern](#entity-pattern)
14. [Model Pattern](#model-pattern)
15. [Mapper Pattern](#mapper-pattern)
16. [DI Pattern — Per-Feature Modules](#di-pattern--per-feature-modules)
17. [BLoC Structure & State Management](#bloc-structure--state-management)
18. [String & Localization Management (RTL Support)](#string--localization-management-rtl-support)
19. [Validator Placement](#validator-placement)
20. [Naming Conventions](#naming-conventions)
21. [Change Safety Protocol](#change-safety-protocol)
22. [Anti-Patterns — Never Do These](#anti-patterns--never-do-these)

---

## Full Folder Tree

```
lib/
├── main.dart                              ← runZonedGuarded + Firebase.initializeApp + DI init + runApp
├── firebase_options.dart                  ← flutterfire CLI output
├── app/
│   ├── app.dart                           ← MaterialApp.router setup + push notification wiring
│   ├── app_bloc_scope.dart                ← app-level MultiBlocProvider
│   ├── pages/                             ← app-level pages (splash, error boundary)
│   ├── router/
│   │   ├── app_router.dart                ← GoRouter instance with deep-link handling
│   │   ├── routes.dart                    ← route name constants
│   │   └── auth_guard.dart                ← redirect based on AuthBloc state
│   └── widgets/                           ← app-level shared widgets (app shell, bottom nav)
├── config/
│   ├── env/
│   │   └── app_env.dart                   ← baseUrl, socketUrl, env flavour
│   └── constants/
│       └── app_constants.dart             ← universal constants (timeouts, limits, page sizes)
├── core/
│   ├── di/
│   │   ├── injection_container.dart       ← composition root: GetIt sl + init()
│   │   ├── core_dependencies.dart         ← logging, storage, network, firebase_auth
│   │   ├── realtime_dependencies.dart     ← Socket.io service (depends on core)
│   │   └── notifications_dependencies.dart ← FCM + DeviceTokenRepository (depends on core)
│   ├── result/
│   │   └── result.dart                    ← Result<T> (Success / Failure_)
│   ├── error/
│   │   ├── failure.dart                   ← Failure sealed class hierarchy
│   │   └── exception.dart                 ← Exception types mirroring Failure
│   ├── usecases/
│   │   └── usecase.dart                   ← UseCase<R, P> & NoParamsUseCase<R>
│   ├── network/
│   │   ├── api_client.dart                ← Dio wrapper + envelope unwrap
│   │   ├── api_response.dart              ← ApiResponse<T> (data + meta)
│   │   ├── auth_interceptor.dart          ← attaches session JWT; on 401 notifies session expired
│   │   ├── session_expired_notifier.dart  ← broadcast stream; AuthBloc listens
│   │   └── connectivity_checker.dart
│   ├── local_storage/
│   │   ├── secure_storage.dart            ← flutter_secure_storage wrapper
│   │   ├── shared_prefs.dart              ← non-sensitive preferences (theme, language)
│   │   └── storage_keys.dart              ← key constants
│   ├── logging/
│   │   ├── app_logger.dart                ← abstract interface
│   │   ├── app_logger_impl.dart           ← logger package impl
│   │   └── bloc_logger_observer.dart      ← BlocObserver → AppLogger
│   ├── firebase_auth/
│   │   ├── firebase_auth_service.dart          ← abstract interface (Google sign-in, ID token)
│   │   └── firebase_auth_service_impl.dart     ← firebase_auth implementation
│   ├── realtime/
│   │   ├── realtime_service.dart               ← abstract interface (connect/on/requestAck/emit)
│   │   ├── socket_io_realtime_service.dart     ← socket_io_client impl (only file importing it)
│   │   ├── realtime_connection_manager.dart    ← auth-state → connect/disconnect
│   │   └── realtime_events.dart                ← event + room name constants (mirror backend)
│   ├── notifications/
│   │   ├── push_notification_service.dart      ← abstract interface
│   │   ├── push_notification_payload.dart      ← value object
│   │   ├── firebase_push_notification_service.dart ← FCM impl
│   │   └── notification_navigation_handler.dart ← tap → router.push bridge
│   ├── presentation/
│   │   ├── theme/
│   │   │   ├── app_theme.dart              ← light theme ThemeData (tokens from theme.md)
│   │   │   ├── app_colors.dart             ← brand primary (#008080) + neutral tokens
│   │   │   └── app_text_styles.dart        ← Manrope & Plus Jakarta Sans styles
│   │   ├── strings/
│   │   │   └── app_strings.dart            ← cross-feature strings
│   │   ├── localization/
│   │   │   ├── app_localizations.dart      ← 4 languages: ur, hi, ar, en
│   │   │   └── rtl_directionality.dart     ← RTL helper widgets
│   │   └── widgets/                        ← reusable UI components (AppButton, AppTextField, ...)
│   ├── validators/                         ← shared validators (2+ features)
│   └── utils/
│       ├── date_formatter.dart
│       ├── duration_formatter.dart         ← seconds to HH:mm:ss format
│       └── share_exporter.dart             ← Excel, PDF, text, image export helper
└── features/
    ├── auth/                               ← Google sign-in, onboarding profile setup
    ├── home/                               ← Dashboard: live-now strip + featured + feed
    ├── tournaments/                        ← List, create, participants, flight records, live standings
    ├── records/                            ← Personal records (private/live), streaming landings
    ├── posts/                              ← Post feed, create, likes, shares, reports
    ├── chat/                               ← 1-1 chat, TikTok-style request, ticks, voice notes
    ├── notifications/                      ← Realtime feed of alerts
    └── settings/                           ← Language (RTL), privacy, notification toggles, edit profile
```

---

## Feature Internal Structure

Every feature has exactly this internal structure:

```
feature_name/
├── di/
│   └── <feature>_dependencies.dart    ← register<Feature>Dependencies(GetIt sl)
├── domain/
│   ├── entities/                      ← immutable, pure Dart
│   ├── repositories/                  ← abstract interfaces only
│   ├── use_cases/                     ← one class per file, returns Result<T>
│   └── validators/                    ← pure Dart bool-returning validators
├── data/
│   ├── models/                        ← hand-written JSON DTOs with fromJson/toJson
│   ├── mappers/                       ← Model ↔ Entity conversion
│   ├── datasources/                   ← <feature>_remote_data_source.dart
│   └── repositories/                  ← concrete impls of domain interfaces
└── presentation/
    ├── pages/                         ← full screens
    ├── widgets/                       ← feature-scoped widgets
    ├── strings/                       ← feature-scoped UI strings
    └── bloc/
        ├── <context>_bloc.dart
        ├── <context>_event.dart
        └── <context>_state.dart
```

---

## Dependency Rule

```
┌──────────────────┐     ┌────────────────────┐
│   Presentation   │     │        Data         │
│  (flutter_bloc)  │     │ (ApiClient, Storage)│
└────────┬─────────┘     └────────┬────────────┘
         │                        │
         ▼                        ▼
    ┌─────────────────────────────────┐
    │            Domain               │
    │       (pure Dart only)          │
    └─────────────────────────────────┘
```

**Never violate:**
- **Domain imports:** `dart:core` only. No Dio, no Flutter, no Firebase, no storage, no third-party.
- **Data imports:** domain + `ApiClient` + storage packages + Firebase SDKs. No Flutter widgets.
- **Presentation imports:** domain entities + `flutter_bloc` + Flutter. No Dio, no data classes, no raw JSON.

---

## Layer Responsibilities

| Layer | Owns | Never touches |
|---|---|---|
| **Domain** | Entities, use-case logic, repository contracts, validators | Dio, Flutter widgets, JSON, storage, logging, Firebase |
| **Data** | Models, mappers, data sources, repository impls | Flutter widgets, Blocs, `BuildContext` |
| **Presentation** | Screens, widgets, Blocs, routing | Dio, repositories directly, raw JSON |
| **Core (cross-cutting)** | Logging, networking, storage, realtime Socket.io, FCM, DI | Feature-specific business logic |

---

## Cross-Cutting Infrastructure

`core/logging/`, `core/network/`, `core/firebase_auth/`, `core/realtime/`, and `core/notifications/` are shared infrastructure. Each exposes an **abstract interface**; only `injection_container.dart` and the corresponding `*_dependencies.dart` module know the concrete implementation.

```
Data sources  ──→  AppLogger (constructor injection)
Repositories  ──→  AppLogger (constructor injection)
Blocs         ──→  no direct logger; BlocLoggerObserver handles lifecycle
App           ──→  FirebaseAuthService + RealtimeService + PushNotificationService
```

**Rule:** Domain layer never imports `AppLogger`, `FirebaseAuthService`, `RealtimeService`, or `PushNotificationService`. Use cases and entities are pure Dart.

### Realtime Lifecycle (`RealtimeService` singleton — `core/realtime/`)

One socket per device, held for the app's lifetime. Files:
- `realtime_service.dart` — abstract interface + `RealtimeConnectionStatus` enum.
- `socket_io_realtime_service.dart` — the only file allowed to import `socket_io_client`.
- `realtime_events.dart` — event + room name constants (e.g. `tournament.subscribe`, `tournament.update`, `record.update`, `chat.new_message`).
- `realtime_connection_manager.dart` — owns *when* to connect; reads the session JWT from `SecureStorage` and drives `connect`/`disconnect`.

---

## `Result<T>` — The Only Error Approach

```dart
// core/result/result.dart
import 'package:pigeonfly_mobile/core/error/failure.dart' as f;

sealed class Result<T> {
  const Result();
  factory Result.success(T data) = Success<T>;
  factory Result.failure(f.Failure failure) = Failure_<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(f.Failure failure) failure,
  }) => switch (this) {
    Success<T>  s => success(s.data),
    Failure_<T> ff => failure(ff.failure),
  };
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure_<T> extends Result<T> {
  final f.Failure failure;
  const Failure_(this.failure);
}
```

---

## `Failure` Hierarchy

Every `Failure` carries three cross-cutting fields:
- `message`: Safe to show to the user.
- `code`: Backend `error.code` (e.g. `unauthorized`, `participant_cap_exceeded`, `not_organizer`).
- `requestId`: Backend `error.request_id` for debugging/support.

```dart
// core/error/failure.dart
sealed class Failure {
  final String message;
  final String? code;
  final String? requestId;
  const Failure(this.message, {this.code, this.requestId});
}

final class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode, super.code, super.requestId});
}

final class ServiceUnavailableFailure extends Failure {
  const ServiceUnavailableFailure({String? code, String? requestId})
      : super('The service is temporarily unavailable. Please try again shortly.',
              code: code, requestId: requestId);
}

final class NetworkFailure extends Failure {
  const NetworkFailure()
      : super('Could not reach the server. Check your connection and try again.');
}

final class ServerUnreachableFailure extends Failure {
  const ServerUnreachableFailure()
      : super('The server is currently unavailable. Please try again later.');
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({String? code, String? requestId})
      : super('Session expired. Please login again.', code: code, requestId: requestId);
}

final class ForbiddenFailure extends Failure {
  const ForbiddenFailure(super.message, {super.code, super.requestId});
}

final class SuspendedFailure extends Failure {
  final DateTime? suspendedUntil;
  const SuspendedFailure(super.message, {this.suspendedUntil, super.code, super.requestId});
}

final class BlockedByUserFailure extends Failure {
  const BlockedByUserFailure({String? code, String? requestId})
      : super('This action is not available.', code: code, requestId: requestId);
}

final class ValidationFailure extends Failure {
  final Map<String, String> fieldErrors;
  const ValidationFailure(super.message,
      {this.fieldErrors = const {}, super.code, super.requestId});
}

final class UnprocessableFailure extends Failure {
  const UnprocessableFailure(super.message, {super.code, super.requestId});
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code, super.requestId});
}

final class ConflictFailure extends Failure {
  const ConflictFailure(super.message, {super.code, super.requestId});
}

final class RateLimitedFailure extends Failure {
  final int? retryAfterSeconds;
  const RateLimitedFailure(super.message,
      {this.retryAfterSeconds, super.code, super.requestId});
}

final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
```

---

## Exception Types

Exceptions mirror the failure hierarchy 1:1. `ApiClient` throws these; `RepositoryImpl._execute` catches them and returns `Result.failure`.

```dart
// core/error/exception.dart
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? details;
  final String? requestId;
  const ServerException(this.message, {this.statusCode, this.code, this.details, this.requestId});
}

class NetworkException implements Exception { const NetworkException(); }
class ServerUnreachableException implements Exception { const ServerUnreachableException(); }
class ServiceUnavailableException implements Exception {
  final String? requestId;
  const ServiceUnavailableException({this.requestId});
}
class UnauthorizedException implements Exception {
  final String? code;
  final String? requestId;
  const UnauthorizedException({this.code, this.requestId});
}
class ForbiddenException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;
  final String? requestId;
  const ForbiddenException(this.message, {this.code, this.details, this.requestId});
}
class SuspendedException implements Exception {
  final String message;
  final DateTime? suspendedUntil;
  final String? requestId;
  const SuspendedException(this.message, {this.suspendedUntil, this.requestId});
}
class BlockedByUserException implements Exception {
  final String? requestId;
  const BlockedByUserException({this.requestId});
}
class ValidationException implements Exception {
  final String message;
  final Map<String, String> fieldErrors;
  final String? code;
  final String? requestId;
  const ValidationException(this.message, {this.fieldErrors = const {}, this.code, this.requestId});
}
class UnprocessableException implements Exception {
  final String message;
  final String? code;
  final String? requestId;
  const UnprocessableException(this.message, {this.code, this.requestId});
}
class NotFoundException implements Exception {
  final String message;
  final String? code;
  final String? requestId;
  const NotFoundException(this.message, {this.code, this.requestId});
}
class ConflictException implements Exception {
  final String message;
  final String? code;
  final String? requestId;
  const ConflictException(this.message, {this.code, this.requestId});
}
class RateLimitedException implements Exception {
  final String message;
  final int? retryAfterSeconds;
  final String? requestId;
  const RateLimitedException(this.message, {this.retryAfterSeconds, this.requestId});
}
class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}
```

---

## `UseCase` Base Classes

```dart
// core/usecases/usecase.dart
abstract class UseCase<R, P> {
  Future<R> call(P params);
}

abstract class NoParamsUseCase<R> {
  Future<R> call();
}
```

- Has params → `implements UseCase<Result<T>, MyParams>`
- No params → `implements NoParamsUseCase<Result<T>>`
- **Never** use `NoParamsUseCase` for a list endpoint — pagination is mandatory.

---

## `ApiClient` Pattern

`core/network/api_client.dart` wraps Dio.
- **Envelope unwrapping:** Unwraps `{ "data": ..., "meta": ... }` and returns `ApiResponse<T>`.
- **Typed exception mapping:** Parses status code and `error` envelope into typed exceptions (`ValidationException`, `UnauthorizedException`, etc.).

```dart
// core/network/api_response.dart
class ApiResponse<T> {
  final T data;
  final Map<String, dynamic>? meta;
  const ApiResponse(this.data, {this.meta});
}
```

---

## `DataSource` Pattern

Data sources call `ApiClient` directly. Each method wraps its call in `try-catch-rethrow` for logging only.

```dart
// features/tournaments/data/datasources/tournaments_remote_data_source.dart
class TournamentsRemoteDataSource {
  const TournamentsRemoteDataSource(this._apiClient, this._logger);
  final ApiClient _apiClient;
  final AppLogger _logger;
  static const _tag = 'TournamentsRemoteDS';

  static const _pathTournaments = '/v1/tournaments';

  Future<TournamentsPageModel> getTournaments({
    String? cursor,
    int limit = 20,
  }) async {
    _logger.debug('getTournaments cursor=$cursor', tag: _tag);
    try {
      final response = await _apiClient.get<List<dynamic>>(
        _pathTournaments,
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );
      final model = TournamentsPageModel(
        items: response.data
            .map((e) => TournamentModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextCursor: response.meta?['next_cursor'] as String?,
        hasMore: response.meta?['has_more'] as bool? ?? false,
      );
      return model;
    } catch (e, st) {
      _logger.warning('getTournaments threw ${e.runtimeType}', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }
}
```

---

## Repository Implementation Pattern

Repositories catch typed exceptions using `_execute<T>` and return `Result.failure`.

```dart
// features/tournaments/data/repositories/tournaments_repository_impl.dart
class TournamentsRepositoryImpl implements TournamentsRepository {
  final TournamentsRemoteDataSource _dataSource;
  final AppLogger _logger;
  const TournamentsRepositoryImpl(this._dataSource, this._logger);
  static const _tag = 'TournamentsRepo';

  @override
  Future<Result<TournamentsPageEntity>> getTournaments(GetTournamentsParams params) =>
      _execute<TournamentsPageEntity>(() async {
        final model = await _dataSource.getTournaments(
          cursor: params.cursor,
          limit: params.limit,
        );
        return TournamentsPageMapper.toEntity(model);
      });

  Future<Result<T>> _execute<T>(Future<T> Function() task) async {
    try {
      final value = await task();
      return Result.success(value);
    } on NetworkException {
      return const Result.failure(NetworkFailure());
    } on ServerUnreachableException {
      return const Result.failure(ServerUnreachableFailure());
    } on ServiceUnavailableException catch (e) {
      return Result.failure(ServiceUnavailableFailure(requestId: e.requestId));
    } on UnauthorizedException catch (e) {
      return Result.failure(UnauthorizedFailure(code: e.code, requestId: e.requestId));
    } on SuspendedException catch (e) {
      return Result.failure(SuspendedFailure(
        e.message,
        suspendedUntil: e.suspendedUntil,
        requestId: e.requestId,
      ));
    } on BlockedByUserException catch (e) {
      return Result.failure(BlockedByUserFailure(requestId: e.requestId));
    } on ForbiddenException catch (e) {
      return Result.failure(ForbiddenFailure(e.message, code: e.code, requestId: e.requestId));
    } on ValidationException catch (e) {
      return Result.failure(ValidationFailure(
        e.message,
        fieldErrors: e.fieldErrors,
        code: e.code,
        requestId: e.requestId,
      ));
    } on UnprocessableException catch (e) {
      return Result.failure(UnprocessableFailure(e.message, code: e.code, requestId: e.requestId));
    } on NotFoundException catch (e) {
      return Result.failure(NotFoundFailure(e.message, code: e.code, requestId: e.requestId));
    } on ConflictException catch (e) {
      return Result.failure(ConflictFailure(e.message, code: e.code, requestId: e.requestId));
    } on RateLimitedException catch (e) {
      return Result.failure(RateLimitedFailure(
        e.message,
        retryAfterSeconds: e.retryAfterSeconds,
        requestId: e.requestId,
      ));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
        requestId: e.requestId,
      ));
    } catch (e, st) {
      _logger.warning('unexpected: ${e.runtimeType}', tag: _tag, error: e, stackTrace: st);
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}
```

---

## Entity, Model & Mapper Patterns

- **Entity:** Immutable plain Dart class in `domain/entities/`, with `copyWith`, `operator ==`, and `hashCode`. Pure Dart only.
- **Model:** Hand-written JSON DTO in `data/models/` with `fromJson` and `toJson`. No `build_runner`.
- **Mapper:** Static class in `data/mappers/` translating Model ↔ Entity. Durations converted between seconds integer and domain representations.

---

## DI Pattern — Per-Feature Modules

Manual `get_it` registration without `@injectable`.

```
features/tournaments/di/tournaments_dependencies.dart
features/auth/di/auth_dependencies.dart
...
```

Composition root:
```dart
// core/di/injection_container.dart
final GetIt sl = GetIt.instance;

Future<void> init() async {
  await registerCoreDependencies(sl);
  registerRealtimeDependencies(sl);
  registerNotificationsDependencies(sl);

  registerAuthDependencies(sl);
  registerHomeDependencies(sl);
  registerTournamentsDependencies(sl);
  registerRecordsDependencies(sl);
  registerPostsDependencies(sl);
  registerChatDependencies(sl);
  registerNotificationsFeatureDependencies(sl);
  registerSettingsDependencies(sl);
}
```

---

## BLoC Structure & State Management

Each feature context has 3 files:
1. `<context>_event.dart`: Sealed class with `Event` suffix.
2. `<context>_state.dart`: Single immutable class with `status` enum (`initial`, `loading`, `loaded`, `error`) and `copyWith`.
3. `<context>_bloc.dart`: Handlers delegate to use cases only. Emits states.

---

## String & Localization Management (RTL Support)

PigeonFly supports 4 languages: **Urdu (`ur`), Hindi (`hi`), Arabic (`ar`), English (`en`)**.
- **Urdu & Arabic are RTL (Right-to-Left).**
- Never use `EdgeInsets.left` / `.right`; use `EdgeInsetsDirectional.start` / `.end`.
- Never use `TextAlign.left` / `.right`; use `TextAlign.start` / `.end`.
- Shared strings live in `core/presentation/strings/app_strings.dart`.
- Feature-scoped strings live in `features/<feature>/presentation/strings/<feature>_strings.dart`.

---

## Naming Conventions

| Component | Pattern | Example |
|---|---|---|
| Entity | `<Noun>Entity` | `TournamentEntity`, `ParticipantEntity`, `RecordEntity` |
| Repository contract | `<Noun>Repository` | `TournamentsRepository` |
| Repository impl | `<Noun>RepositoryImpl` | `TournamentsRepositoryImpl` |
| UseCase | `<Verb><Noun>UseCase` | `GetTournamentsUseCase`, `RecordFlightUseCase` |
| Bloc | `<BoundedContext>Bloc` | `TournamentsBloc`, `LiveRecordBloc` |
| Event | `<BoundedContext><Action>Event` | `TournamentStartedEvent`, `FlightRecordedEvent` |
| State | `<BoundedContext>State` | `TournamentsState`, `LiveRecordState` |
| DataSource | `<Noun>RemoteDataSource` | `TournamentsRemoteDataSource` |
| Model | `<Noun>Model` | `TournamentModel` |
| Mapper | `<Noun>Mapper` | `TournamentMapper` |
| Feature DI module | `<feature>_dependencies.dart` | `tournaments_dependencies.dart` |
| Feature DI function | `register<Feature>Dependencies(GetIt sl)` | `registerTournamentsDependencies(sl)` |
| Feature strings | `<feature>_strings.dart` | `tournaments_strings.dart` |

---

## Anti-Patterns — Never Do These

1. **No business logic in UI or Blocs** — always in use cases or domain services.
2. **No Dio in Domain or Presentation** — only through `ApiClient` in `data/`.
3. **No hardcoded left/right layout** — violates RTL requirements for Urdu/Arabic.
4. **No code generators** (`freezed`, `json_serializable`, `build_runner`).
5. **No raw exceptions crossing into Blocs** — always `Result<T>`.
6. **No silent catches** — must map to typed `Failure`.
7. **No PII in logs** — phone numbers, names, chat content.
8. **Never include unreturned pigeons in the tournament average** — "Not returned" pigeons are excluded from calculation.

---

*PigeonFly Mobile Architecture · Version 1.0 · 2026-10-03*
