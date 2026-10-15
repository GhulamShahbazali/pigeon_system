import '../../../core/network/api_client.dart';
import '../../../core/result/result.dart';
import 'models/tournament_card_model.dart';
import 'models/tournament_detail_model.dart';

class TournamentsRepository {
  final ApiClient _apiClient;

  TournamentsRepository(this._apiClient);

  Future<Result<List<TournamentCardModel>>> getTournaments({String tab = 'all'}) async {
    return _apiClient.get<List<TournamentCardModel>>(
      '/tournaments',
      queryParameters: {'tab': tab},
      fromJson: (data) {
        if (data is List) {
          return data
              .map((e) => TournamentCardModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

  /// Tournaments organized by a specific user — for a profile's "Tournaments" list.
  Future<Result<List<TournamentCardModel>>> getUserTournaments(String userId) async {
    return _apiClient.get<List<TournamentCardModel>>(
      '/tournaments/by-user/$userId',
      fromJson: (data) => data is List
          ? data.map((e) => TournamentCardModel.fromJson(e as Map<String, dynamic>)).toList()
          : <TournamentCardModel>[],
    );
  }

  Future<Result<TournamentDetailModel>> getTournamentDetail(String id) async {
    return _apiClient.get<TournamentDetailModel>(
      '/tournaments/$id',
      fromJson: (data) => TournamentDetailModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<Result<List<ParticipantRowModel>>> getStandings(String tournamentId) async {
    return _apiClient.get<List<ParticipantRowModel>>(
      '/tournaments/$tournamentId/participants',
      fromJson: (data) {
        if (data is List) {
          return data
              .map((e) => ParticipantRowModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

  Future<Result<Map<String, dynamic>>> createTournament(Map<String, dynamic> body) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/tournaments',
      data: body,
      fromJson: (data) => data is Map<String, dynamic> ? data : {},
    );
  }

  Future<Result<Map<String, dynamic>>> addParticipant(String tournamentId, Map<String, dynamic> body) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/tournaments/$tournamentId/participants',
      data: body,
      fromJson: (data) => data is Map<String, dynamic> ? data : {},
    );
  }

  Future<Result<Map<String, dynamic>>> getParticipantDetail(String tournamentId, String participantId) async {
    return _apiClient.get<Map<String, dynamic>>(
      '/tournaments/$tournamentId/participants/$participantId',
      fromJson: (data) => data is Map<String, dynamic> ? data : {},
    );
  }

  Future<Result<Map<String, dynamic>>> recordFlight(
    String tournamentId,
    String participantId,
    Map<String, dynamic> body,
  ) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/tournaments/$tournamentId/participants/$participantId/flights',
      data: body,
      fromJson: (data) => data is Map<String, dynamic> ? data : {},
    );
  }

  Future<Result<Map<String, dynamic>>> updateFlight(
    String tournamentId,
    String participantId,
    String flightId,
    Map<String, dynamic> body,
  ) async {
    return _apiClient.patch<Map<String, dynamic>>(
      '/tournaments/$tournamentId/participants/$participantId/flights/$flightId',
      data: body,
      fromJson: (data) => data is Map<String, dynamic> ? data : {},
    );
  }

  Future<Result<void>> deleteFlight(
    String tournamentId,
    String participantId,
    String flightId,
  ) async {
    return _apiClient.delete<void>(
      '/tournaments/$tournamentId/participants/$participantId/flights/$flightId',
    );
  }

  Future<Result<void>> followTournament(String id) async {
    return _apiClient.post<void>('/tournaments/$id/follow');
  }

  Future<Result<void>> unfollowTournament(String id) async {
    return _apiClient.delete<void>('/tournaments/$id/follow');
  }

  Future<Result<void>> likeTournament(String id) async {
    return _apiClient.post<void>('/tournaments/$id/like');
  }

  Future<Result<void>> unlikeTournament(String id) async {
    return _apiClient.delete<void>('/tournaments/$id/like');
  }
}
