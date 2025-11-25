# "StreamFlix Live Monitor" - vendo o que os usuários estão assistindo agora.

## Passo 1: Preparar o Projeto
Crie uma pasta nova e rode no terminal:

```bash
mkdir cassandra-web
cd cassandra-web
npm init -y
npm install fastify cassandra-driver cors
``` 

## Passo 2: O Backend (Node.js + Fastify)
Crie um arquivo chamado server.js. Esse código conecta no seu Docker e expõe duas rotas: uma para gravar e outra para ler.

```javascript
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
```

## Passo 3: O Frontend (HTML Único)
Crie um arquivo index.html na mesma pasta. Vou usar um CSS simples (Tailwind via CDN) para ficar com cara de apresentação profissional. Ele vai ter um script que consulta a API a cada 2 segundos.

```html
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <title>StreamFlix - Monitor Cassandra</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-900 text-white p-10 font-sans">

    <div class="max-w-4xl mx-auto">
        <h1 class="text-4xl font-bold mb-8 text-blue-500">StreamFlix <span class="text-gray-400 text-xl">| Cassandra Real-time Ingestion</span></h1>

        <div class="bg-gray-800 p-6 rounded-lg mb-8 shadow-lg border border-gray-700">
            <h2 class="text-xl mb-4 font-semibold">Simular Novo Acesso (Write Path)</h2>
            <div class="flex gap-4">
                <input id="filmeInput" type="text" placeholder="Nome do Filme (ex: Velozes e Furiosos)" 
                       class="flex-1 p-3 rounded bg-gray-700 border border-gray-600 focus:outline-none focus:border-blue-500">
                
                <select id="deviceInput" class="p-3 rounded bg-gray-700 border border-gray-600">
                    <option value="Mobile">Celular</option>
                    <option value="TV 4K">TV Sala</option>
                    <option value="Web">Computador</option>
                </select>

                <button onclick="enviarDados()" 
                        class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-6 rounded transition">
                    Dar Play
                </button>
            </div>
        </div>

        <div class="bg-gray-800 p-6 rounded-lg shadow-lg border border-gray-700">
            <div class="flex justify-between items-center mb-4">
                <h2 class="text-xl font-semibold">Últimas Visualizações (Read Path)</h2>
                <span class="text-xs text-green-400 animate-pulse">● Live Sync (2s)</span>
            </div>
            
            <table class="w-full text-left">
                <thead>
                    <tr class="text-gray-400 border-b border-gray-700">
                        <th class="pb-2">Data/Hora (Clustering Key)</th>
                        <th class="pb-2">Filme</th>
                        <th class="pb-2">Dispositivo</th>
                    </tr>
                </thead>
                <tbody id="tabelaCorpo">
                    </tbody>
            </table>
        </div>
    </div>

    <script>
        const API_URL = 'http://localhost:3000';

        async function enviarDados() {
            const filme = document.getElementById('filmeInput').value;
            const dispositivo = document.getElementById('deviceInput').value;
            if(!filme) return alert("Digite um filme!");

            await fetch(`${API_URL}/assistir`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ filme, dispositivo })
            });

            document.getElementById('filmeInput').value = '';
            carregarDados(); // Atualiza na hora
        }

        async function carregarDados() {
            const response = await fetch(`${API_URL}/historico`);
            const dados = await response.json();
            
            const tbody = document.getElementById('tabelaCorpo');
            tbody.innerHTML = '';

            dados.forEach(dado => {
                const dataFormatada = new Date(dado.data_hora).toLocaleString('pt-BR');
                const row = `
                    <tr class="border-b border-gray-700 hover:bg-gray-750 transition">
                        <td class="py-3 text-blue-300 font-mono text-sm">${dataFormatada}</td>
                        <td class="py-3 font-bold">${dado.filme_titulo}</td>
                        <td class="py-3 text-gray-400">${dado.dispositivo}</td>
                    </tr>
                `;
                tbody.innerHTML += row;
            });
        }

        // Loop de atualização automática (Polling)
        setInterval(carregarDados, 2000);
        carregarDados();
    </script>
</body>
</html>
```

## Apresentação
- Gere a tabela
```sql
USE streamflix;

CREATE TABLE IF NOT EXISTS historico_visualizacao (
    usuario_id UUID,
    data_hora timestamp,
    filme_titulo text,
    dispositivo text,
    minuto_parada int,
    PRIMARY KEY ((usuario_id), data_hora)
) WITH CLUSTERING ORDER BY (data_hora DESC);
```

- Rode o servidor: `node server.js`

- Abra o HTML: Abra o index.html no navegador.
