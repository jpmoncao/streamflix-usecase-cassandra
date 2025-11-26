-- Para garantir um ambiente limpo, removemos o keyspace se ele já existir
DROP KEYSPACE IF EXISTS streamflix;











-- Criando o keyspace (banco de dados) 
--    * O atributo 'class' define a estratégia de replicação
--    * O 'replication_factor' define o número de réplicas dos dados
--    * Aqui usamos 'SimpleStrategy' com fator de replicação 1 para simplicidade, ou seja, sem replicação (ambiente de desenvolvimento)
CREATE KEYSPACE IF NOT EXISTS streamflix 
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};











-- Usando o keyspace criado
USE streamflix;











-- 1. Criando a tabela de histórico de visualização
--      * A chave primária é composta por 'usuario_id' (partição) e 'data_hora' (clustering)
--      * A ordenação é feita em ordem decrescente de 'data_hora'
CREATE TABLE IF NOT EXISTS historico_visualizacao (
    usuario_id UUID,
    data_hora timestamp,
    filme_titulo text,
    dispositivo text,
    minuto_parada int,
    status text,
    PRIMARY KEY ((usuario_id), data_hora)
) WITH CLUSTERING ORDER BY (data_hora DESC);











-- 2. Inserindo dados FORA DE ORDEM cronológica propositalmente
INSERT INTO historico_visualizacao (usuario_id, data_hora, filme_titulo, dispositivo, status)
VALUES (550e8400-e29b-41d4-a716-446655440000, '2025-01-15 10:00:00', 'Star Wars 4', 'TV', 'completo');

INSERT INTO historico_visualizacao (usuario_id, data_hora, filme_titulo, dispositivo, status)
VALUES (550e8400-e29b-41d4-a716-446655440000, '2025-11-15 20:00:00', 'Star Wars 6', 'Mobile', 'pausado');

INSERT INTO historico_visualizacao (usuario_id, data_hora, filme_titulo, dispositivo, status)
VALUES (550e8400-e29b-41d4-a716-446655440000, '2025-06-15 14:30:00', 'Star Wars 5', 'Web', 'completo');











-- 3. Consultando os dados para verificar a ordem cronológica
--     * A consulta deve retornar os registros em ordem decrescente de 'data_hora'
SELECT * FROM historico_visualizacao WHERE usuario_id = 550e8400-e29b-41d4-a716-446655440000;











-- 4. Atualizando o status do filme "Star Wars 6" para "finalizado" (mesmo usuario_id e data_hora)
INSERT INTO historico_visualizacao (usuario_id, data_hora, filme_titulo, dispositivo, status)
VALUES (550e8400-e29b-41d4-a716-446655440000, '2025-12-25 20:00:00', 'Star Wars 6', 'Mobile', 'finalizado');


-- 5. Consultando novamente para verificar a atualização
SELECT * FROM historico_visualizacao WHERE usuario_id = 550e8400-e29b-41d4-a716-446655440000;











-- 6. Inserindo um registro temporário com TTL de 10 segundos
INSERT INTO historico_visualizacao (usuario_id, data_hora, filme_titulo, dispositivo, status)
VALUES (550e8400-e29b-41d4-a716-446655440000, toTimestamp(now()), 'Trailer Star Wars 7', 'TV', 'promo')
USING TTL 15;











-- 7. Consultando para verificar a inserção do registro temporário
--    * Aguarde mais de 15 segundos e execute a consulta novamente para ver que o registro foi removido automaticamente
SELECT * FROM historico_visualizacao WHERE usuario_id = 550e8400-e29b-41d4-a716-446655440000;











-- 8. Consultando registros feitos a partir de dispositivos 'Mobile' (Query Full Scan)
--      * Nota: A consulta acima resultará em erro porque 'dispositivo' não faz parte da chave primária ou de um índice secundário.
--      * Para consultas eficientes, é necessário modelar os dados de acordo com os padrões de consulta esperados.
SELECT * FROM historico_visualizacao WHERE dispositivo = 'Mobile';











-- 9. Consulta alternativa usando ALLOW FILTERING
--      * Nota: O uso de ALLOW FILTERING pode levar a problemas de desempenho em grandes volumes de dados. Use com cautela.
--      * Esta consulta deve ser evitada em ambientes de produção.
--      * O ideal é criar uma tabela ou índice secundário adequado para consultas frequentes.
SELECT * FROM historico_visualizacao WHERE dispositivo = 'Mobile' ALLOW FILTERING;











-- 10. Excluindo todos os registros do usuário específico
DELETE FROM historico_visualizacao WHERE usuario_id = 550e8400-e29b-41d4-a716-446655440000;










