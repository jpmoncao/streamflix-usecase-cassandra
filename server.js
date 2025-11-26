// server.js
const Fastify = require('fastify');
const cassandra = require('cassandra-driver');
const cors = require('@fastify/cors');

const app = Fastify({ logger: true });
app.register(cors);

// 1. Configuração do Cliente Cassandra
// Lembre-se: 'datacenter1' é o padrão do Docker oficial
const client = new cassandra.Client({
    contactPoints: ['localhost'],
    localDataCenter: 'datacenter1',
    keyspace: 'streamflix'
});

// ID fixo para demonstração (para vermos o histórico de UM usuário crescendo)
const ID_USUARIO_DEMO = '550e8400-e29b-41d4-a716-446655440000';

// Rota 1: Simular alguém dando "Play" (INSERT)
app.post('/assistir', async (request, reply) => {
    const { filme, dispositivo } = request.body;

    const query = `
    INSERT INTO historico_visualizacao (usuario_id, data_hora, filme_titulo, dispositivo, minuto_parada) 
    VALUES (?, toTimestamp(now()), ?, ?, 0)
  `;

    await client.execute(query, [ID_USUARIO_DEMO, filme, dispositivo], { prepare: true });

    return { status: 'Gravado com sucesso no Cassandra!' };
});

// Rota 2: Dashboard em Tempo Real (SELECT)
app.get('/historico', async (request, reply) => {
    // O Cassandra já retorna ordenado por data (DESC) por causa do CLUSTERING ORDER que definimos
    const query = `
    SELECT * FROM historico_visualizacao 
    WHERE usuario_id = ? 
    LIMIT 10
  `;

    const result = await client.execute(query, [ID_USUARIO_DEMO], { prepare: true });
    return result.rows;
});

// Inicialização
const start = async () => {
    try {
        await client.connect();
        console.log('Conectado ao Cassandra!');
        await app.listen({ port: 3000 });
    } catch (err) {
        app.log.error(err);
        process.exit(1);
    }
};
start();