# "StreamFlix Live Monitor" - vendo o que os usuários estão assistindo agora.

## Passo 1: Inicializar o container do banco de dados
```bash
# Expondo a porta 9042 (nativa do protocolo CQL)
docker run --name cassandra-demo -p 9042:9042 -d cassandra:latest

# Verificar se subiu (espere aparecer "state: U/N" - Up/Normal)
docker exec -it cassandra-demo nodetool status

# Entrar no terminal CQL (CQLSH)
docker exec -it cassandra-demo cqlsh
```

## Passo 2: Preparar o Projeto
Crie uma pasta nova e rode no terminal:

```bash
cd cassandra-web
npm init -y
npm install fastify cassandra-driver cors
``` 

## Apresentação
- Rode o servidor: `node server.js`

- Abra o HTML: Abra o index.html no navegador.
