const http = require('http');
const Pokemon = require('./buscarPokemon');
const db = require('./manejoDB');
const puerto = 3000;

const server = http.createServer((req, res) => {

    if (req.method == "OPTIONS") {
        res.statusCode = 204;
        res.setHeader("Access-Control-Allow-Origin", "*");
        res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
        res.setHeader("Access-Control-Allow-Headers", "Content-Type");
        res.setHeader('Content-Type', 'text/plain');
        res.end();
        console.log(`HTTP/1.1 204 OPTIONS ${Date()}`);
        return;
    }

    if (req.method != 'POST' || req.url != '/pokemon') {
        res.statusCode = 405;
        res.end(JSON.stringify({ error: "Método o contexto no válido." }));
        console.log(`HTTP/1.1 ${res.statusCode} Método o contexto no válido. ${Date()}`);
        return;
    }

    let data = '';

    req.on('data', (chunk) => {
        data += chunk;
    });

    req.on('end', () => {
        const pokemon = data.trim().toLowerCase();
        db.consultarPokemon(pokemon, (err, result) => {
            if (result) {
                res.statusCode = 200;
                res.end(JSON.stringify(result));
                console.log(`HTTP/1.1 ${res.statusCode} Pokemon encontrado en BD ${Date()}`);
                return;
            }
            Pokemon.buscarPokemon(pokemon, (err, apiData) => {
                if (err) {
                    res.statusCode = 404;
                    res.end(JSON.stringify({ error: err }));
                    console.log(`HTTP/1.1 ${res.statusCode} ${err} ${Date()}`);
                    return;
                }
                db.insertarPokemon(apiData, (err) => {
                    if (err) {
                        res.statusCode = 500;
                        res.end(JSON.stringify({ error: 'Error al guardar en la base de datos.' }));
                        console.log(`HTTP/1.1 ${res.statusCode} Error al guardar en BD ${Date()}`);
                        return;
                    }
                    db.consultarPokemon(pokemon, (err, result) => {
                        if (err) {
                            res.statusCode = 500;
                            res.end(JSON.stringify({ error: 'Error al consultar la base de datos.' }));
                            console.log(`HTTP/1.1 ${res.statusCode} Error BD después de guardar ${Date()}`);
                            return;
                        }
                        res.statusCode = 200;
                        res.end(JSON.stringify(result));
                        console.log(`HTTP/1.1 ${res.statusCode} Pokémon guardado y enviado al cliente ${Date()}`);
                    });
                });
            });
        });
    });
});

server.listen(puerto, () => {
    console.log(`Servidor funcionando en el puerto ${puerto}...`);
});