// Port of Keep/Data/DayPhase.swift SolarMath + Daylight.elevationContext.
// Fixture matches demo/script.md: Delhi GPS, 11 Sep 2026.

export const FIXTURE = {
  latitude: 28.61,
  longitude: 77.21,
  dayOfYear: 254,
  utcOffsetHours: 5.5,
};

const M = {
  fullCircle: 360,
  halfCircle: 180,
  rightAngle: 90,
  obliquity: 23.44,
  tropicalYear: 365,
  solsticeOffset: 10,
  degreesPerHour: 15,
  solarMidday: 12,
  approximateSunset: 18,
  sunriseRefraction: 0.83,
  nightElevation: -6,
  twilightElevation: 8,
  noonHourAngle: 22,
  noonElevation: 28,
  dayNightElevation: -0.5,
  minimumSpan: 0.5,
  bothSides: 2,
  sunProgressMax: 1.2,
  sunProgressMin: -0.2,
  hoursPerDay: 24,
};

const deg = (d) => (d * Math.PI) / M.halfCircle;
const rad = (r) => (r * M.halfCircle) / Math.PI;
const wrap = (h) => {
  let v = h % M.hoursPerDay;
  if (v < 0) v += M.hoursPerDay;
  return v;
};

export function filmWeather(hour) {
  const h = Math.floor(((hour % 24) + 24) % 24);
  if (h < 4) return "clear";
  if (h < 7) return "fog";
  if (h < 11) return "cloudy";
  if (h < 14) return "clear";
  if (h < 17) return "rain";
  if (h < 20) return "storm";
  return "snow";
}

export function solarAtHour(hour, lat = FIXTURE.latitude, lon = FIXTURE.longitude) {
  const dayAngle = (M.fullCircle / M.tropicalYear) * (FIXTURE.dayOfYear + M.solsticeOffset);
  const declination = -M.obliquity * Math.cos(deg(dayAngle));
  const latRad = deg(lat);
  const decRad = deg(declination);
  const utcHours = wrap(hour - FIXTURE.utcOffsetHours);
  const solarTime = wrap(utcHours + lon / M.degreesPerHour);
  const hourAngleDeg = (solarTime - M.solarMidday) * M.degreesPerHour;
  const sinEl =
    Math.sin(latRad) * Math.sin(decRad) +
    Math.cos(latRad) * Math.cos(decRad) * Math.cos(deg(hourAngleDeg));
  const elevation = rad(Math.asin(Math.min(1, Math.max(-1, sinEl))));
  const refraction = Math.sin(deg(-M.sunriseRefraction));
  const cosHA =
    (refraction - Math.sin(latRad) * Math.sin(decRad)) /
    (Math.cos(latRad) * Math.cos(decRad));
  const haDeg = rad(Math.acos(Math.min(1, Math.max(-1, cosHA))));
  const daySpan = Math.max(M.minimumSpan, (M.bothSides * haDeg) / M.degreesPerHour);
  const sunProgress = (hourAngleDeg + haDeg) / (M.bothSides * haDeg);
  const nightSpan = Math.max(M.minimumSpan, M.hoursPerDay - daySpan);
  const hoursAfterSunset = wrap(solarTime - (M.solarMidday + haDeg / M.degreesPerHour));
  const moonProgress = Math.min(1, Math.max(0, hoursAfterSunset / nightSpan));
  const rising = hourAngleDeg < 0;
  let phase = "afternoon";
  if (elevation < M.nightElevation) phase = "night";
  else if (elevation < M.twilightElevation) phase = rising ? "dawn" : "dusk";
  else if (Math.abs(hourAngleDeg) < M.noonHourAngle && elevation >= M.noonElevation) phase = "noon";
  else if (rising) phase = "morning";
  return {
    phase,
    sunProgress: Math.min(M.sunProgressMax, Math.max(M.sunProgressMin, sunProgress)),
    moonProgress: Math.min(1, Math.max(0, moonProgress)),
    elevation,
    isDay: elevation > M.dayNightElevation,
  };
}
