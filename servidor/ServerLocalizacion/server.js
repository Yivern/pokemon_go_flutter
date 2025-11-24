const http = require('http');
const puerto = 3001;

let baseLat = 0;
let baseLng = 0;

async function PokemonCercano(lat, lng) {
    const randomOffset = (min, max) => Math.random() * (max - min) + min;
    const newLat = lat + randomOffset(-0.0009, 0.0009);
    const newLng = lng + randomOffset(-0.0009, 0.0009);
    const pokemonId = Math.floor(Math.random() * 1025) + 1;
   
    const response = await fetch('http://192.168.88.251:3000/pokemon', {
        method: "POST",
        headers: { "Content-Type": "text/plain" },
        body: pokemonId
    });
    const data = await response.json();

    return { lat: newLat, lng: newLng, pokemonData: data };
}

const server = http.createServer(async (req, res) => {
    if (req.method == "OPTIONS") {
        res.statusCode = 204;
        res.setHeader("Access-Control-Allow-Origin", "*");
        res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
        res.setHeader("Access-Control-Allow-Headers", "Content-Type");
        res.setHeader('Content-Type', 'application/json');
        res.end('OPTIONS Realizado con exito.');
        console.log(`HTTP/1.1 ${res.statusCode} OPTIONS ${Date()}`);
        return;
    }

    if (req.method != 'POST' || req.url != '/localizacion') {
        res.statusCode = 405;
        res.end(JSON.stringify({ error: "Método o contexto no válido." }));
        console.log(`HTTP/1.1 ${res.statusCode} Método o contexto no válido. ${Date()}`);
        return;
    }

    let body = '';
    req.on('data', chunk => {
        body += chunk;
    });

    req.on('end', async () => {
        const data = JSON.parse(body);
        console.log(body);
        baseLat = data['latitude'];
        baseLng = data['longitude'];

        const pokeUbi = await PokemonCercano(baseLat, baseLng);
        res.statusCode = 200;
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(pokeUbi));
        console.log(`HTTP/1.1 ${res.statusCode} Pokemon enviado con éxito ${Date()}`);
    });
});

server.listen(puerto, () => {
    console.log(`Servidor funcionando en el puerto ${puerto}...`);
});