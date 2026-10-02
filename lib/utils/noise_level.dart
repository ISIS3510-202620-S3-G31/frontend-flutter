const _minDb = 40.0;
const _maxDb = 100.0;

const meterSegments = 12;

/// Mic level as 0..1 (40 dB → 0, 100 dB → 1).
double levelFromDb(double db) =>
    ((db - _minDb) / (_maxDb - _minDb)).clamp(0.0, 1.0);

/// How many of the 12 meter segments are lit (84 dB → 9, as in the mock-up).
int litSegments(double db) => (levelFromDb(db) * meterSegments).round();

String zoneLabel(double db) => db < 60
    ? 'Soft'
    : db < 80
    ? 'Medium'
    : 'Strong';
