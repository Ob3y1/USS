class ServiceConf {
  static const domainNameServer = 'http://localhost:8000';       // Laravel
  static const fastApiServer = 'http://localhost:8003';          // FastAPI

  static const login = '/api/login';
  static const schedule = '/api/getObserverschedule';
  static const getIncidents = '/api/PendingCheatingIncidents';
  static const updateIncident = '/api/updateCheatingIncidents';
  static const updateprofileuser = '/api/updateprofileuser';
  static const showprofileuser = '/api/showprofileuser';
  static const logoutEndpoint = '/api/logout';

  static const saveViolation = '/api/save_violation';
  static const startCheatDetection = '/start_cheat_detection';
  static const stopCheatDetection = '/stop_cheat_detection';
  static const getViolations = '/violations';
}