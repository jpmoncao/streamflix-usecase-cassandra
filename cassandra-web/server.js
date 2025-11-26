const Fastify = require('fastify');
const cassandra = require('cassandra-driver');
const cors = require('@fastify/cors');

const app = Fastify({ logger: true });

// Registrar CORS para permitir que o HTML local acesse a API
app.register(cors, {
    origin: true
});

// 1. Configuração do Cliente Cassandra
const client = new cassandra.Client({
    contactPoints: ['localhost'],
    localDataCenter: 'datacenter1', // Importante: deve bater com o docker
    keyspace: 'streamflix'
});

// ID fixo para demonstração
const ID_USUARIO_DEMO = '550e8400-e29b-41d4-a716-446655440000';

// Rota 1: Simular alguém dando "Play" (INSERT - Write Path)
app.post('/assistir', async (request, reply) => {
    const { filme, dispositivo } = request.body;

    // Inserindo com "Assistindo" como status padrão para compor com seu script SQL
    const query = `
    INSERT INTO historico_visualizacao (usuario_id, data_hora, filme_titulo, dispositivo, minuto_parada, status) 
    VALUES (?, toTimestamp(now()), ?, ?, 0, 'Assistindo')
  `;

    try {
        await client.execute(query, [ID_USUARIO_DEMO, filme, dispositivo], { prepare: true });
        return { status: 'Gravado com sucesso no Cassandra!' };
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ error: 'Erro ao gravar no Cassandra' });
    }
});

// Rota 2: Dashboard em Tempo Real (SELECT - Read Path)
app.get('/historico', async (request, reply) => {
    // O Cassandra já retorna ordenado por data (DESC) devido ao CLUSTERING ORDER
    const query = `
    SELECT * FROM historico_visualizacao 
    WHERE usuario_id = ? 
    LIMIT 10
  `;

    try {
        const result = await client.execute(query, [ID_USUARIO_DEMO], { prepare: true });
        return result.rows;
    } catch (error) {
        request.log.error(error);
        return reply.code(500).send({ error: 'Erro ao ler do Cassandra' });
    }
});

// Inicialização
const start = async () => {
    try {
        await client.connect();
        console.log('✅ Conectado ao Cluster Cassandra!');
        await app.listen({ port: 3000 });
        console.log('🚀 Servidor rodando em http://localhost:3000');
    } catch (err) {
        app.log.error(err);
        process.exit(1);
    }
};
start();