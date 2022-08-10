-- Grupo: Humberto Giuri
-- Curso:"Engenharia da Computação
-- Matrícula: 2018103846

DROP TABLE IF EXISTS "Schedule";

-- Criando a tabela Schedule (PostgreSQL 10)
CREATE TABLE "Schedule" (
	"time" integer,
	"#t" integer NOT NULL,
	"op" character NOT NULL,
	"attr" character NOT NULL,
	UNIQUE ("time")
);

-- function signature (PostgreSQL 10)
CREATE OR REPLACE FUNCTION testeEquivalenciaPorConflito () 
RETURNS integer AS $$
    DECLARE
        -- Declarando variáveis necessárias
        schedule_inicio         INTEGER;
        schedule_fim            INTEGER;
        schedule_record_inicio  RECORD;
        schedule_record_fim     RECORD;
		time_id_1				INTEGER;
		tr_1 					INTEGER;
		op_1					CHARACTER(1);
		attr_1					CHARACTER(1);
		time_commit				INTEGER;

    BEGIN
		-- Criando tabela para servir de grafo
        CREATE TEMP TABLE IF NOT EXISTS "serialization_graph" (
            "T_inicio" INTEGER NOT NULL,
            "T_fim" INTEGER NOT NULL
        );
		
        -- Iterando sobre a tabela
        FOR schedule_record_inicio IN SELECT * FROM "Schedule" LOOP
            -- Separando as informações da linha e variáveis    
            time_id_1 := schedule_record_inicio."time";
            tr_1 := schedule_record_inicio."#t";
            op_1 := schedule_record_inicio."op";
          	attr_1 := schedule_record_inicio."attr";
			
			IF op_1 = 'C' THEN
				CONTINUE;
			
			ELSE
				-- Descobrindo o time em que a transação ocorreu
				SELECT s."time" INTO time_COMMIT FROM "Schedule" AS s WHERE s."op" = 'C' AND s."#t" = tr_1;

				FOR schedule_record_fim IN SELECT * FROM "Schedule" AS s WHERE (
							s."time" > time_id_1 AND
							s."time" < time_commit 	AND 
							s."attr" = attr_1 AND 
							s."op" != 'C' AND 
							s."#t" != tr_1
						) LOOP
					
					IF op_1 = 'R' AND schedule_record_fim."op" = 'W' THEN
						INSERT INTO "serialization_graph"
						VALUES(tr_1, schedule_record_fim."#t");
						
					ELSIF op_1 = 'W' THEN
						INSERT INTO "serialization_graph"
						VALUES(tr_1, schedule_record_fim."#t");
					ELSE
						CONTINUE;
					END IF;
				END LOOP;
			END IF;
        END LOOP;
		
		FOR schedule_record_fim IN SELECT * FROM "serialization_graph" LOOP
			RAISE NOTICE '% %', schedule_record_fim."T_inicio", schedule_record_fim."T_fim";
		END LOOP;
		
        DROP TABLE "serialization_graph";
    	RETURN 1;

    END;
$$ LANGUAGE plpgsql;


-- Example_01 (PostgreSQL 10)
INSERT INTO "Schedule" ("time", "#t", "op", "attr") VALUES
(1, 1,  'R',  'X'),
(2, 2,  'R',  'X'),
(3, 2,  'W',  'X'),
(4, 1,  'W',  'X'),
(5, 2,  'C',  '-'),
(6, 1,  'C',  '-');

-- calling function
SELECT testeEquivalenciaPorConflito() AS resp;

