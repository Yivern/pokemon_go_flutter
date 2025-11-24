const https = require('https');

function buscarPokemon(pokemon, callback) {
    try {
        https.get(`https://pokeapi.co/api/v2/pokemon/${pokemon.toLowerCase()}`, (response) => {
            let data = '';

            response.on('data', (body) => {
                data += body;
            });

            response.on('end', () => {
                if (response.statusCode != 200) {
                    return callback('Pokemon no encontrado.');
                }
                const jsonData = JSON.parse(data);
                const name = jsonData.name.toUpperCase();
                const id = jsonData.id;
                const heigt = `${jsonData.height} cm`;
                const temp = jsonData.weight / 10;
                const weight = `${temp} kg`;

                var gif = jsonData.sprites.versions['generation-v']['black-white'].animated.front_default;
                if (!gif) {
                    gif = jsonData.sprites.front_default;
                }
                callback(null, { name, gif, id, heigt, weight });
            });
        });
    } catch {
        return callback('Hubo un error en la solicitud.', null);
    }
}

module.exports.buscarPokemon = buscarPokemon;