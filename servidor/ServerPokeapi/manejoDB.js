const sqlite = require('sqlite3').verbose();
const db = new sqlite.Database('./db/pokemon.db');

db.run(`
    CREATE TABLE IF NOT EXISTS pokemon (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL UNIQUE,
        peso TEXT NOT NULL,
        altura TEXT NOT NULL,
        img TEXT
    )
`);

function insertarPokemon(data, callback) {
    db.run("INSERT INTO pokemon (id, nombre, peso, altura, img) VALUES (?, ?, ?, ?, ?)", [data.id, data.name.toLowerCase(), data.weight, data.heigt, data.gif],
        function (err) {
            callback(err);
        }
    );
}

function consultarPokemon(name, callback) {
    db.get("SELECT * FROM pokemon WHERE nombre = ? OR id = ? ", [name, name], (err, row) => {
        if (err) {
            return callback(err, null);
        }
        callback(null, row);
    });
}

module.exports.insertarPokemon = insertarPokemon;
module.exports.consultarPokemon = consultarPokemon;