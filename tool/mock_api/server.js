#!/usr/bin/env node
/**
 * Dummy API for the fleet dashboard.
 *
 * Serves the same endpoints (and the same JSON envelopes) as the real
 * server at 203.100.57.59:3000, so the whole dashboard can be reviewed
 * without the backend being up.
 *
 * Two things it does that the real API currently does not, on purpose:
 *   - sends CORS headers, so Chrome does not block the browser build;
 *   - sends latitude/longitude on drowsiness events and air readings, so
 *     the maps that are permanently empty today actually have something
 *     to draw.
 *
 *   node tool/mock_api/server.js            # fixtures, listens on :4000
 *   PORT=5000 node tool/mock_api/server.js
 *
 * Sign in with demo / demo, or register a new account on the sign-up page and
 * use that. Accounts are in memory only: restarting forgets everyone but demo.
 *
 * PROXY MODE — real data, in Chrome:
 *
 *   API_PROXY=http://203.100.57.59:3000 node tool/mock_api/server.js
 *
 * Forwards every request to the real API and adds the CORS headers it omits,
 * so the browser build can use real accounts and real data. Point the app at
 * this server either way:
 *
 *   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000/api/v1
 *
 * Native builds (macOS, Android, iOS) are not subject to CORS and can talk to
 * http://203.100.57.59:3000/api/v1 directly, with no proxy at all.
 */
'use strict';

const http = require('http');
const crypto = require('crypto');

const PORT = Number(process.env.PORT || 4000);
const PREFIX = '/api/v1';

/**
 * When set, every request is forwarded to this origin instead of being served
 * from the fixtures below, and the CORS headers the real API omits are added
 * on the way back.
 *
 * That is the only way `flutter run -d chrome` can reach the real server: it
 * sends no Access-Control-Allow-Origin, so Chrome blocks the response before
 * the app ever sees it. Native builds (macOS, Android, iOS) have no such
 * restriction and can point straight at the real host.
 *
 *   API_PROXY=http://203.100.57.59:3000 node tool/mock_api/server.js
 */
const PROXY_TARGET = process.env.API_PROXY || '';

// ---------------------------------------------------------------- fixtures

const VEHICLES = [
  { id: '1', vin: '1HGBH41JXMN109186', plate: 'B 1234 XYZ', driverId: '11', driver: 'Andi Prasetyo',  type: 'Truck',  device: 'DEV-001', imei: '860123456789011', lat: -6.1751, lng: 106.8650, speed: 48,  move: 'moving', dev: 'online',  safe: 'safe',    active: true  },
  { id: '2', vin: '2HGES16593H123457', plate: 'B 5678 ABC', driverId: '12', driver: 'Budi Santoso',   type: 'Van',    device: 'DEV-002', imei: '860123456789012', lat: -6.2297, lng: 106.8295, speed: 0,   move: 'idle',   dev: 'online',  safe: 'safe',    active: true  },
  { id: '3', vin: '3FAHP0HA5AR112233', plate: 'B 9012 DEF', driverId: '13', driver: 'Citra Dewi',     type: 'Truck',  device: 'DEV-003', imei: '860123456789013', lat: -6.2615, lng: 106.7810, speed: 62,  move: 'moving', dev: 'online',  safe: 'warning', active: true  },
  { id: '4', vin: '4T1BF1FK5CU998877', plate: 'B 3456 GHI', driverId: '14', driver: 'Dimas Wibowo',   type: 'Pickup', device: 'DEV-004', imei: '860123456789014', lat: -6.1478, lng: 106.9004, speed: 12,  move: 'moving', dev: 'online',  safe: 'alert',   active: true  },
  { id: '5', vin: '5NPE24AF4FH334455', plate: 'B 7890 JKL', driverId: '15', driver: 'Eka Nurhaliza',  type: 'Van',    device: 'DEV-005', imei: '860123456789015', lat: -6.3021, lng: 106.8951, speed: 0,   move: 'idle',   dev: 'offline', safe: 'safe',    active: false },
  { id: '6', vin: '6G1ZT51806F556677', plate: 'B 2468 MNO', driverId: '16', driver: 'Fajar Ramadhan', type: 'Truck',  device: 'DEV-006', imei: '860123456789016', lat: -6.1934, lng: 106.8220, speed: 35,  move: 'moving', dev: 'online',  safe: 'safe',    active: true  },
];

const BEHAVIORS = ['drowsiness', 'yawn', 'drowsy_score_on', 'distraction'];
const RISKS = ['high', 'medium', 'low'];
const REVIEWS = ['new', 'confirmed', 'false_alarm', 'follow_up_required', 'followed_up'];
const AREAS = ['Tol Jagorawi KM 12', 'Jl. Sudirman', 'Tol Cikampek KM 40', 'Jl. Gatot Subroto', 'Tol JORR KM 8'];

/** Deterministic PRNG: the same seed always yields the same fleet, so a
 *  reload never reshuffles the numbers you are in the middle of reading. */
function rng(seed) {
  let state = seed >>> 0;
  return () => {
    state = (state * 1664525 + 1013904223) >>> 0;
    return state / 4294967296;
  };
}

const DAY = 86400000;
const startOfToday = () => { const d = new Date(); d.setHours(0, 0, 0, 0); return d; };

/** 45 days of events per vehicle, weighted so night hours and a couple of
 *  drivers stand out — a flat distribution makes every chart look broken. */
function buildEvents() {
  const events = [];
  let id = 1000;

  VEHICLES.forEach((vehicle, vIndex) => {
    const rand = rng(7 + vIndex * 31);
    const perDay = vehicle.safe === 'alert' ? 5 : vehicle.safe === 'warning' ? 3 : 2;

    for (let dayBack = 44; dayBack >= 0; dayBack--) {
      const count = Math.round(rand() * perDay);
      for (let i = 0; i < count; i++) {
        // Night-shift bias: most events land between 22:00 and 05:00.
        const hour = rand() < 0.62
          ? [22, 23, 0, 1, 2, 3, 4][Math.floor(rand() * 7)]
          : Math.floor(rand() * 24);

        const at = new Date(startOfToday().getTime() - dayBack * DAY);
        at.setHours(hour, Math.floor(rand() * 60), Math.floor(rand() * 60), 0);

        const risk = rand() < 0.22 ? 'high' : rand() < 0.6 ? 'medium' : 'low';
        events.push({
          drowsiness_id: id++,
          vehicle_id: vehicle.id,
          vehicle_identification_number: vehicle.vin,
          plate_number: vehicle.plate,
          user_id: Number(vehicle.driverId),
          driver_name: vehicle.driver,
          event_time: at.toISOString(),
          status: 'detected',
          risk_level: risk,
          behavior_type: BEHAVIORS[Math.floor(rand() * BEHAVIORS.length)],
          img_path: `https://picsum.photos/seed/drowsy${id}/640/360`,
          video_path: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          location_name: AREAS[Math.floor(rand() * AREAS.length)],
          latitude: vehicle.lat + (rand() - 0.5) * 0.12,
          longitude: vehicle.lng + (rand() - 0.5) * 0.12,
          speed_at_event: Math.round(rand() * 90),
          speed_source: 'telemetry',
          telemetry_timestamp: at.toISOString(),
          trip_id: 500 + Math.floor(rand() * 40),
          telemetry_status_id: 1,
          review_status: REVIEWS[Math.floor(rand() * REVIEWS.length)],
        });
      }
    }
  });

  return events.sort((a, b) => new Date(b.event_time) - new Date(a.event_time));
}

const EVENTS = buildEvents();

/** Hourly cabin-air samples for any requested day, generated on demand so
 *  every date the user picks has data instead of only one lucky day. */
function readingsForDate(dateStr) {
  const day = new Date(`${dateStr}T00:00:00`);
  if (Number.isNaN(day.getTime())) return [];
  if (day.getTime() > Date.now()) return []; // the future has no readings

  const seed = Number(dateStr.replace(/-/g, ''));
  const rand = rng(seed);
  const rows = [];

  VEHICLES.filter((vehicle) => vehicle.active).forEach((vehicle, index) => {
    for (let hour = 6; hour <= 20; hour += 1) {
      const at = new Date(day);
      at.setHours(hour, 0, 0, 0);
      if (at.getTime() > Date.now()) break;

      // Air worsens through the afternoon, so the trend line has a shape.
      const load = Math.sin(((hour - 6) / 14) * Math.PI);
      rows.push({
        vehicle_id: vehicle.id,
        vehicle_identification_number: vehicle.vin,
        plate_number: vehicle.plate,
        timestamp: at.toISOString(),
        aqi: Math.round(38 + load * 70 + rand() * 25 + index * 4),
        co2: Math.round(520 + load * 380 + rand() * 90),
        co: Number((1.2 + load * 2.6 + rand()).toFixed(1)),
        o2: Number((20.9 - load * 0.5 - rand() * 0.2).toFixed(1)),
        temperature: Number((25 + load * 5 + rand() * 1.5).toFixed(1)),
        humidity: Math.round(55 + load * 15 + rand() * 8),
        latitude: vehicle.lat + (rand() - 0.5) * 0.1,
        longitude: vehicle.lng + (rand() - 0.5) * 0.1,
      });
    }
  });

  return rows.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
}

// ------------------------------------------------------------- aggregation

const dateOnly = (iso) => iso.slice(0, 10);

function eventsFor(vin, query) {
  const start = query.start_date ? new Date(`${query.start_date}T00:00:00`) : null;
  const end = query.end_date ? new Date(`${query.end_date}T23:59:59`) : null;
  const userId = query.user_id ? Number(query.user_id) : null;

  return EVENTS.filter((event) => {
    if (vin && event.vehicle_identification_number !== vin && event.vehicle_id !== vin) return false;
    const at = new Date(event.event_time);
    if (start && at < start) return false;
    if (end && at > end) return false;
    if (userId && event.user_id !== userId) return false;
    return true;
  });
}

function countBy(list, pick) {
  return list.reduce((acc, item) => {
    const key = pick(item);
    acc[key] = (acc[key] || 0) + 1;
    return acc;
  }, {});
}

function buildReport(vin, query) {
  const scoped = eventsFor(vin, query);
  const total = scoped.length;
  const high = scoped.filter((event) => event.risk_level === 'high').length;

  const byDay = countBy(scoped, (event) => dateOnly(event.event_time));
  const byHour = countBy(scoped, (event) => new Date(event.event_time).getHours());
  const byReview = countBy(scoped, (event) => event.review_status);
  const byDriver = {};
  scoped.forEach((event) => {
    const key = `${event.user_id}|${event.driver_name}`;
    byDriver[key] = (byDriver[key] || 0) + 1;
  });

  const topDriver = Object.entries(byDriver).sort((a, b) => b[1] - a[1])[0];
  const peakDay = Object.entries(byDay).sort((a, b) => b[1] - a[1])[0];
  const peakHour = Object.entries(byHour).sort((a, b) => b[1] - a[1])[0];
  const behaviourCounts = countBy(scoped, (event) => event.behavior_type);
  const dominant = Object.entries(behaviourCounts).sort((a, b) => b[1] - a[1])[0];

  const reviewed = total - (byReview.new || 0);
  const completion = total === 0 ? 0 : Number(((reviewed / total) * 100).toFixed(1));
  const riskScore = total === 0 ? 0 : Math.min(100, Math.round((high / total) * 160 + Math.min(total, 60) * 0.5));

  const weekdayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const weekdays = weekdayNames.map((name, index) => {
    const dayEvents = scoped.filter((event) => new Date(event.event_time).getDay() === index);
    const behaviours = countBy(dayEvents, (event) => event.behavior_type);
    const drivers = {};
    dayEvents.forEach((event) => {
      const key = `${event.user_id}|${event.driver_name}`;
      drivers[key] = (drivers[key] || 0) + 1;
    });

    return {
      weekday: name,
      weekday_index: index,
      total_events: dayEvents.length,
      behaviors: {
        drowsiness: behaviours.drowsiness || 0,
        yawn: behaviours.yawn || 0,
        drowsy_score_on: behaviours.drowsy_score_on || 0,
        distraction: behaviours.distraction || 0,
        other: 0,
      },
      dominant_behavior: Object.entries(behaviours).sort((a, b) => b[1] - a[1])[0]?.[0] || '',
      top_drivers: Object.entries(drivers)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 3)
        .map(([key, count]) => ({
          user_id: Number(key.split('|')[0]),
          driver_name: key.split('|')[1],
          total_events: count,
          percentage: dayEvents.length === 0 ? 0 : Number(((count / dayEvents.length) * 100).toFixed(1)),
        })),
    };
  });

  return {
    summary: {
      vehicle_id: vin,
      total_events: total,
      high_risk_events: high,
      peak_hour: peakHour ? Number(peakHour[0]) : 0,
      peak_date: peakDay ? peakDay[0] : null,
    },
    review_summary: {
      total_events: total,
      new: byReview.new || 0,
      confirmed: byReview.confirmed || 0,
      false_alarm: byReview.false_alarm || 0,
      follow_up_required: byReview.follow_up_required || 0,
      followed_up: byReview.followed_up || 0,
      reviewed_total: reviewed,
      review_completion_rate: completion,
      false_alarm_rate: total === 0 ? 0 : Number((((byReview.false_alarm || 0) / total) * 100).toFixed(1)),
      closure_rate: total === 0 ? 0 : Number((((byReview.followed_up || 0) / total) * 100).toFixed(1)),
    },
    risk_summary: {
      risk_level: riskScore >= 70 ? 'high' : riskScore >= 40 ? 'medium' : total === 0 ? 'no_data' : 'low',
      risk_score: riskScore,
      headline: total === 0
        ? 'No drowsiness events detected'
        : `${high} high-risk events out of ${total}`,
      short_summary: total === 0
        ? 'No drowsiness events were detected for the selected period.'
        : `Night driving between ${peakHour ? peakHour[0] : '?'}:00 and ${peakHour ? Number(peakHour[0]) + 1 : '?'}:00 accounts for most detections.`,
      primary_finding: {
        title: 'Peak detection hour',
        value: peakHour ? `${String(peakHour[0]).padStart(2, '0')}:00` : '-',
        description: 'Most drowsiness events cluster in this hour of the day.',
      },
      main_contributor: {
        user_id: topDriver ? Number(topDriver[0].split('|')[0]) : null,
        driver_name: topDriver ? topDriver[0].split('|')[1] : '',
        total_events: topDriver ? topDriver[1] : 0,
        percentage: topDriver && total ? Number(((topDriver[1] / total) * 100).toFixed(1)) : 0,
        description: 'Driver with the highest share of detections in this period.',
      },
      dominant_behavior: {
        key: dominant ? dominant[0] : '',
        label: dominant ? dominant[0].replace(/_/g, ' ') : '',
        description: 'Most frequently detected behaviour.',
      },
      review_backlog: {
        new_events: byReview.new || 0,
        review_completion_rate: completion,
        description: 'Events still waiting for a supervisor review.',
      },
      recommended_actions: [
        { priority: 'high', title: 'Rotate night-shift drivers', description: 'Detections concentrate in the small hours; shorten consecutive night runs.' },
        { priority: 'medium', title: 'Clear the review backlog', description: `${byReview.new || 0} events have not been reviewed yet.` },
        { priority: 'low', title: 'Recalibrate cabin cameras', description: 'A high false-alarm rate usually points at camera placement.' },
      ],
      flags: [
        { type: 'night_driving', severity: 'high', label: 'Night driving concentration' },
        { type: 'repeat_offender', severity: 'medium', label: 'Repeat contributor detected' },
      ],
    },
    events_by_day: Object.entries(byDay)
      .sort((a, b) => a[0].localeCompare(b[0]))
      .map(([date, count]) => ({ event_date: date, total_events: count })),
    events_by_hour: Array.from({ length: 24 }, (_, hour) => ({
      event_hour: hour,
      total_events: byHour[hour] || 0,
    })),
    weekday_behavior_summary: weekdays,
  };
}

// ----------------------------------------------------------------- routing

const ok = (data, extra = {}) => ({ status: 'success', stat_code: 200, data, ...extra });

/** A real-looking HS256 JWT so AuthService can read `exp` and the user out of it. */
function issueToken(user, ttlSeconds = 3600) {
  const base64 = (obj) => Buffer.from(JSON.stringify(obj)).toString('base64url');
  const head = base64({ alg: 'HS256', typ: 'JWT' });
  const body = base64({
    // `exp` only has second resolution, so without a nonce two tokens issued
    // in the same second come out byte-identical — and a refresh would look
    // like it changed nothing.
    jti: crypto.randomBytes(8).toString('hex'),
    sub: user.user_id,
    user_id: user.user_id,
    username: user.username,
    fullname: user.fullname,
    email: user.email,
    role: user.role,
    exp: Math.floor(Date.now() / 1000) + ttlSeconds,
  });
  const sig = crypto.createHmac('sha256', 'mock-secret').update(`${head}.${body}`).digest('base64url');
  return `${head}.${body}.${sig}`;
}

// ------------------------------------------------------------------- auth
//
// The real API's auth routes are not documented anywhere in this repo, so
// these mirror the shape lib/services/auth_service.dart parses: an access
// token, a refresh token, and a user object. Accounts live in memory only —
// restarting the server forgets everyone but the seed below.

const USERS = [
  {
    user_id: '1',
    username: 'demo',
    password: 'demo',
    fullname: 'Demo User',
    email: 'demo@fleetsafe.test',
    role: 'Supervisor',
    division: 'Operations',
  },
];

/** refresh token -> user_id, so a refresh can only renew a session we issued. */
const REFRESH_TOKENS = new Map();

/**
 * Lets a route answer with something other than 200.
 *
 * The real API at 203.100.57.59 sends two different error envelopes, and the
 * mock copies both so the app is exercised against what it will really meet:
 *   400 -> {status: 'error', stat_code, message}
 *   401 -> {stat_code, status: 'Your username / password wrong', message}
 */
const status = (code, message) => ({
  __status: code,
  __body: code === 401
    ? { stat_code: 401, status: 'Your username / password wrong', message }
    : { status: 'error', stat_code: code, message },
});

const publicUser = (user) => ({
  user_id: user.user_id,
  username: user.username,
  fullname: user.fullname,
  email: user.email,
  role: user.role,
  status: 'active',
});

function sessionFor(user) {
  const refreshToken = crypto.randomBytes(24).toString('hex');
  REFRESH_TOKENS.set(refreshToken, user.user_id);
  return ok({
    token: issueToken(user),
    refreshToken,
    user: publicUser(user),
  });
}

function vehicleStatus() {
  const now = Date.now();
  const items = VEHICLES.map((vehicle, index) => {
    const lastSeen = vehicle.dev === 'offline' ? 240 : index * 2 + 1;
    return {
      vehicle_id: vehicle.id,
      vehicle_identification_number: vehicle.vin,
      plate_number: vehicle.plate,
      driver_name: vehicle.driver,
      last_telemetry_time: new Date(now - lastSeen * 60000).toISOString(),
      last_seen_minutes: lastSeen,
      latitude: vehicle.lat,
      longitude: vehicle.lng,
      speed: vehicle.speed,
      device_status: vehicle.dev,
      movement_status: vehicle.move,
      safety_status: vehicle.safe,
      display_status: vehicle.dev === 'offline' ? 'offline' : vehicle.safe !== 'safe' ? vehicle.safe : vehicle.move,
      status_reason: vehicle.dev === 'offline'
        ? 'No telemetry for over 4 hours'
        : vehicle.safe === 'alert'
          ? 'Drowsiness alert in the last hour'
          : 'Reporting normally',
    };
  });

  return {
    summary: {
      total_vehicles: items.length,
      online_vehicles: items.filter((item) => item.device_status === 'online').length,
      moving: items.filter((item) => item.movement_status === 'moving').length,
      idle: items.filter((item) => item.movement_status === 'idle').length,
      warning: items.filter((item) => item.safety_status === 'warning').length,
      offline: items.filter((item) => item.device_status === 'offline').length,
      alert: items.filter((item) => item.safety_status === 'alert').length,
    },
    vehicles: items,
  };
}

function registryItem(vehicle) {
  return {
    vehicle_id: vehicle.id,
    vehicle_identification_number: vehicle.vin,
    plate_number: vehicle.plate,
    vehicle_type: vehicle.type,
    driver_id: vehicle.driverId,
    driver_name: vehicle.driver,
    device_id: vehicle.device,
    imei: vehicle.imei,
    is_active: vehicle.active,
    notes: vehicle.active ? 'In service' : 'Workshop — engine service',
    created_dt: '2026-01-15T08:00:00.000Z',
    updated_dt: new Date().toISOString(),
    photo_url: `https://picsum.photos/seed/${vehicle.device}/480/320`,
  };
}

/** Latest wearable reading per driver. Values wander a little each call so
 *  the page visibly refreshes, but stay inside plausible human ranges. */
function driverVitals() {
  const now = Date.now();
  const rand = rng(Math.floor(now / 60000)); // steady within the same minute

  return VEHICLES.map((vehicle, index) => {
    const onShift = vehicle.dev === 'online';
    const strain = vehicle.safe === 'alert' ? 1 : vehicle.safe === 'warning' ? 0.5 : 0;

    return {
      driver_id: vehicle.driverId,
      user_id: Number(vehicle.driverId),
      driver_name: vehicle.driver,
      vehicle_id: vehicle.id,
      vehicle_identification_number: vehicle.vin,
      plate_number: vehicle.plate,
      // A driver who is off shift has no live reading at all, which is a
      // different thing from a reading of zero.
      heart_rate: onShift ? Math.round(68 + strain * 26 + rand() * 12) : null,
      spo2: onShift ? Math.round(97 - strain * 2 + rand() * 2) : null,
      temperature: onShift ? Number((36.4 + strain * 0.6 + rand() * 0.3).toFixed(1)) : null,
      work_duration_minutes: onShift ? 90 + index * 55 + Math.round(rand() * 40) : null,
      activity: onShift ? 'active' : 'off_shift',
      is_active: onShift,
      status: strain === 1 ? 'alert' : strain > 0 ? 'warning' : 'normal',
      timestamp: new Date(now - index * 90000).toISOString(),
    };
  });
}

const ROUTES = [
  ['POST', /^\/auth\/register$/, (_m, _q, body) => {
    const fullname = String(body.fullname || '').trim();
    const username = String(body.username || '').trim();
    const password = String(body.password || '');

    if (!fullname || !username || !password) {
      return status(400, 'fullname, username, password, role and division are required');
    }
    if (USERS.some((user) => user.username.toLowerCase() === username.toLowerCase())) {
      return status(409, `Username "${username}" is already taken.`);
    }

    USERS.push({
      user_id: String(USERS.length + 1),
      username,
      password,
      fullname,
      email: String(body.email || `${username}@fleetsafe.test`),
      role: String(body.role || '').trim() || 'Member',
      division: String(body.division || '').trim() || 'Unassigned',
    });
    // Deliberately no session: the app sends the new user to the login page.
    return ok({ username, created: true });
  }],

  ['POST', /^\/auth\/login$/, (_m, _q, body) => {
    const username = String(body.username || '').trim();
    const password = String(body.password || '');
    const user = USERS.find(
      (candidate) => candidate.username.toLowerCase() === username.toLowerCase()
        && candidate.password === password,
    );
    if (!user) return status(401, 'Your username / password wrong');
    return sessionFor(user);
  }],

  ['POST', /^\/auth\/refresh$/, (_m, _q, body) => {
    // The real server reads `refreshToken` only — `refresh_token` does not
    // even get past its required-field check.
    const presented = String(body.refreshToken || '');
    if (!presented) return status(401, 'Refresh token is required');

    const userId = REFRESH_TOKENS.get(presented);
    if (!userId) return status(401, 'Invalid or expired refresh token');

    // Rotate: the old token is spent, exactly as a real server would do.
    REFRESH_TOKENS.delete(presented);
    const user = USERS.find((candidate) => candidate.user_id === userId);
    if (!user) return status(401, 'That account no longer exists.');
    return sessionFor(user);
  }],

  ['POST', /^\/auth\/logout$/, (_m, _q, _body, headers) => {
    const auth = String(headers.authorization || '');
    if (!auth.toLowerCase().startsWith('bearer ')) {
      return status(401, 'No token provide');
    }
    // The real server retires the session; here there is nothing to retire
    // beyond the refresh tokens, which the next login replaces anyway.
    return ok({ loggedOut: true });
  }],

  ['GET', /^\/vehicles\/status$/, () => ok(vehicleStatus())],

  ['GET', /^\/vehicles$/, (_m, query) => ok({
    vehicles: VEHICLES.map(registryItem),
    summary: {
      total_vehicles: VEHICLES.length,
      active_vehicles: VEHICLES.filter((vehicle) => vehicle.active).length,
      inactive_vehicles: VEHICLES.filter((vehicle) => !vehicle.active).length,
    },
    page: Number(query.page || 1),
    limit: Number(query.limit || 50),
  })],

  ['GET', /^\/vehicles\/([^/]+)$/, (match) => {
    const vehicle = VEHICLES.find((item) => item.id === match[1] || item.vin === match[1]);
    return vehicle ? ok(registryItem(vehicle)) : null;
  }],

  ['GET', /^\/drivers\/vitals$/, () => ok(driverVitals())],

  ['GET', /^\/air-monitor\/get-air-by-date$/, (_m, query) =>
    ok(readingsForDate(query.date || new Date().toISOString().slice(0, 10)))],

  ['GET', /^\/drowsiness\/report\/([^/]+)\/export\/csv$/, () => 'CSV'],

  ['GET', /^\/drowsiness\/report\/([^/]+)$/, (match, query) =>
    ok(buildReport(decodeURIComponent(match[1]), query))],

  ['GET', /^\/drowsiness\/events\/([^/]+)$/, (match, query) =>
    ok(eventsFor(decodeURIComponent(match[1]), query).slice(0, Number(query.limit || 100)))],

  ['GET', /^\/drowsiness\/drivers\/([^/]+)$/, (match, query) => {
    const scoped = eventsFor(decodeURIComponent(match[1]), query);
    const drivers = {};
    scoped.forEach((event) => {
      const key = `${event.user_id}|${event.driver_name}`;
      drivers[key] = drivers[key] || { total: 0, high: 0, last: event.event_time };
      drivers[key].total += 1;
      if (event.risk_level === 'high') drivers[key].high += 1;
      if (event.event_time > drivers[key].last) drivers[key].last = event.event_time;
    });
    return ok(Object.entries(drivers).map(([key, value]) => ({
      user_id: Number(key.split('|')[0]),
      driver_name: key.split('|')[1],
      total_events: value.total,
      high_risk_events: value.high,
      last_event_time: value.last,
    })));
  }],

  ['GET', /^\/drowsiness\/driver-behavior$/, (_m, query) => {
    const scoped = eventsFor(query.vehicle_id || null, query);
    const drivers = {};
    scoped.forEach((event) => {
      const key = `${event.user_id}|${event.driver_name}|${event.vehicle_identification_number}`;
      drivers[key] = drivers[key] || { events: [] };
      drivers[key].events.push(event);
    });

    return ok(Object.entries(drivers).map(([key, value]) => {
      const [userId, , vin] = key.split('|');
      const behaviours = countBy(value.events, (event) => event.behavior_type);
      const risks = countBy(value.events, (event) => event.risk_level);
      return {
        user_id: Number(userId),
        vehicle_id: vin,
        internal_vehicle_id: VEHICLES.find((item) => item.vin === vin)?.id ?? null,
        total_events: value.events.length,
        latest_event_time: value.events[0].event_time,
        behaviors: {
          drowsiness_episode: behaviours.drowsiness || 0,
          distraction: behaviours.distraction || 0,
          yawn: behaviours.yawn || 0,
          drowsy: behaviours.drowsiness || 0,
          drowsy_score_on: behaviours.drowsy_score_on || 0,
        },
        risk_summary: {
          high: risks.high || 0,
          medium: risks.medium || 0,
          low: risks.low || 0,
        },
      };
    }));
  }],

  ['PATCH', /^\/drowsiness\/review\/(\d+)$/, (match, _q, body) => {
    const event = EVENTS.find((item) => item.drowsiness_id === Number(match[1]));
    if (!event) return null;
    Object.assign(event, {
      review_status: body.review_status || event.review_status,
      review_note: body.review_note ?? event.review_note,
      follow_up_note: body.follow_up_note ?? event.follow_up_note,
      reviewed_by: body.reviewed_by ?? 'demo',
      reviewed_at: new Date().toISOString(),
    });
    return ok(event);
  }],
];

/** Pipes one request through to [PROXY_TARGET] and the answer back. */
function forward(req, res, url) {
  const target = new URL(PROXY_TARGET);
  const isHttps = target.protocol === 'https:';
  const transport = isHttps ? require('https') : http;

  // Drop the hop-by-hop headers and our own host: the upstream needs its own.
  const headers = { ...req.headers };
  delete headers.host;
  delete headers.connection;
  delete headers['accept-encoding'];

  const upstream = transport.request(
    {
      protocol: target.protocol,
      hostname: target.hostname,
      port: target.port || (isHttps ? 443 : 80),
      method: req.method,
      path: url.pathname + url.search,
      headers,
    },
    (answer) => {
      console.log(`${req.method} ${url.pathname}${url.search} -> ${answer.statusCode} (proxied)`);

      // Copy the upstream's headers, but never let it overwrite the CORS ones
      // already set above — those are the whole point of proxying.
      for (const [key, value] of Object.entries(answer.headers)) {
        if (key.toLowerCase().startsWith('access-control-')) continue;
        res.setHeader(key, value);
      }
      res.writeHead(answer.statusCode || 502);
      answer.pipe(res);
    },
  );

  upstream.on('error', (error) => {
    console.error(`${req.method} ${url.pathname} -> proxy error: ${error.message}`);
    res.writeHead(502, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'error',
      message: `Could not reach ${PROXY_TARGET}: ${error.message}`,
    }));
  });

  req.pipe(upstream);
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const query = Object.fromEntries(url.searchParams);

  // The real API sends none of these, which is why the browser build fails
  // against it. Sending them here keeps `flutter run -d chrome` usable.
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PATCH,PUT,DELETE,OPTIONS');

  if (req.method === 'OPTIONS') {
    res.writeHead(204).end();
    return;
  }

  if (PROXY_TARGET) {
    forward(req, res, url);
    return;
  }

  if (!url.pathname.startsWith(PREFIX)) {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'error', message: 'Not found' }));
    return;
  }

  const path = url.pathname.slice(PREFIX.length) || '/';
  let raw = '';
  req.on('data', (chunk) => { raw += chunk; });
  req.on('end', () => {
    let body = {};
    try { body = raw ? JSON.parse(raw) : {}; } catch (_) { body = {}; }

    for (const [method, pattern, handler] of ROUTES) {
      if (req.method !== method) continue;
      const match = path.match(pattern);
      if (!match) continue;

      const result = handler(match, query, body, req.headers);
      const code = result === null ? 404 : (result && result.__status) || 200;
      console.log(`${req.method} ${url.pathname}${url.search} -> ${code}`);

      if (result === null) {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'error', message: 'Not found' }));
        return;
      }
      if (result && result.__status) {
        res.writeHead(result.__status, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(result.__body));
        return;
      }
      if (result === 'CSV') {
        const rows = eventsFor(decodeURIComponent(match[1]), query);
        const csv = ['event_time,driver_name,behavior_type,risk_level,review_status,location']
          .concat(rows.map((event) => [
            event.event_time, event.driver_name, event.behavior_type,
            event.risk_level, event.review_status, event.location_name,
          ].join(',')))
          .join('\n');
        res.writeHead(200, {
          'Content-Type': 'text/csv',
          'Content-Disposition': `attachment; filename="drowsiness-${match[1]}.csv"`,
        });
        res.end(csv);
        return;
      }

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(result));
      return;
    }

    console.log(`${req.method} ${url.pathname} -> 404 (no route)`);
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'error', message: `No route for ${path}` }));
  });
});

// Starting twice is normal: the editor task fires on every launch, and a
// proxy from an earlier session may still be up. Exiting quietly leaves that
// one serving instead of dumping an unhandled EADDRINUSE stack trace into the
// task output, where it reads like a real failure.
server.on('error', (error) => {
  if (error.code === 'EADDRINUSE') {
    console.log(`Port ${PORT} already serving — reusing it (EADDRINUSE).`);
    process.exit(0);
  }
  throw error;
});

server.listen(PORT, () => {
  if (PROXY_TARGET) {
    console.log(`CORS proxy on http://localhost:${PORT}${PREFIX}`);
    console.log(`Forwarding every request to ${PROXY_TARGET} — real accounts, real data.`);
  } else {
    console.log(`Mock fleet API on http://localhost:${PORT}${PREFIX}`);
    console.log(`${EVENTS.length} drowsiness events across ${VEHICLES.length} vehicles`);
    console.log(`${VEHICLES.length} driver vital-sign readings`);
    console.log('Sign in with demo / demo, or register a new account.');
  }
  console.log('\nRun the app against it with:');
  console.log(`  flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:${PORT}${PREFIX}`);
});
