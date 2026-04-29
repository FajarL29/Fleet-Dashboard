const WebSocket = require('ws');

const serverUrl = 'ws://203.100.57.59:3300/?vehicle_id=1210&device=GPS';
const ws = new WebSocket(serverUrl);

// Rute Tol Japek (Titik Utama)
const japekRoute = [
    { lat: -6.2447, lng: 106.8903 }, // Halim
    { lat: -6.2486, lng: 106.9734 }, // Bekasi Barat
    { lat: -6.2558, lng: 107.0195 }, // Bekasi Timur
    { lat: -6.2753, lng: 107.0754 }, // Tambun
    { lat: -6.2874, lng: 107.1356 }, // Cikarang Barat
    { lat: -6.3265, lng: 107.1729 }, // Cikarang Pusat
    { lat: -6.3772, lng: 107.2954 }, // Karawang Barat
    { lat: -6.3989, lng: 107.3546 }, // Karawang Timur
    { lat: -6.4021, lng: 107.4475 }, // Cikampek
];

function interpolate(p1, p2, fraction) {
    return {
        lat: p1.lat + (p2.lat - p1.lat) * fraction,
        lng: p1.lng + (p2.lng - p1.lng) * fraction
    };
}

ws.on('open', function open() {
    console.log('✅ Simulator Ultra-Smooth Japek Started');

    let routeIndex = 0;
    let fraction = 0;
    
    /**
     * TUNING ZONE
     * stepSize: 0.005 artinya butuh 200 step untuk pindah antar gerbang tol.
     * Interval: 200ms artinya mengirim data 5x dalam 1 detik.
     */
    const stepSize = 0.001; 
    const updateInterval = 200; 

    setInterval(() => {
        const startNode = japekRoute[routeIndex];
        const endNode = japekRoute[(routeIndex + 1) % japekRoute.length];

        const currentPos = interpolate(startNode, endNode, fraction);

        // Menghitung Heading secara dinamis agar icon menghadap ke arah jalan yang benar
        const heading = Math.atan2(endNode.lng - startNode.lng, endNode.lat - startNode.lat) * 180 / Math.PI;

        const gpsData = {
            event: 'GpsDataReceived',
            target: 'DASHBOARD',
            vehicle_id: '999',
            gps_lat: currentPos.lat,
            gps_lng: currentPos.lng,
            speed_kmph: 120 + Math.random() * 10,
            heading: heading, 
            temp_sensor: 32
        };

        const gpsData1 = {
            event: 'GpsDataReceived',
            target: 'DASHBOARD',
            vehicle_id: '1210',
            gps_lat: currentPos.lat,
            gps_lng: currentPos.lng,
            speed_kmph: 120 + Math.random() * 10,
            heading: heading, 
            temp_sensor: 32
        };

        const gpsData2 = {
            event: 'GpsDataReceived',
            target: 'DASHBOARD',
            vehicle_id: '1234',
            gps_lat: currentPos.lat,
            gps_lng: currentPos.lng,
            speed_kmph: 120 + Math.random() * 10,
            heading: heading, 
            temp_sensor: 32
        };

        ws.send(JSON.stringify(gpsData));
        // ws.send(JSON.stringify(gpsData1));
        // ws.send(JSON.stringify(gpsData2));
        
        // Progress log dikurangi agar terminal tidak spamming, muncul tiap 10%
        if (Math.round(fraction * 100) % 10 === 0) {
            console.log(`🚗 OTW Checkpoint ${(routeIndex + 1)}: ${(fraction * 100).toFixed(0)}%`);
        }

        fraction += stepSize;

        if (fraction >= 1) {
            fraction = 0;
            routeIndex = (routeIndex + 1) % japekRoute.length;
        }
    }, updateInterval); 
});

ws.on('error', (err) => console.log('❌ Error:', err));
ws.on('close', () => console.log('🔌 Disconnected'));