USE streamflix;

CREATE TABLE IF NOT EXISTS historico_visualizacao (
    usuario_id UUID,
    data_hora timestamp,
    filme_titulo text,
    dispositivo text,
    minuto_parada int,
    PRIMARY KEY ((usuario_id), data_hora)
) WITH CLUSTERING ORDER BY (data_hora DESC);