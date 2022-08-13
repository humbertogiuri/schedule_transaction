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
		loops 					INTEGER;

    BEGIN
		-- Criando tabela para servir de grafo
        CREATE TEMP TABLE IF NOT EXISTS "node" (
            "t_inicio" INTEGER NOT NULL,
            "t_fim" INTEGER NOT NULL
        ) ON COMMIT DELETE ROWS;
		
        -- Iterando sobre a tabela e formando o grafo
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
				SELECT s."time" INTO time_commit FROM "Schedule" AS s WHERE s."op" = 'C' AND s."#t" = tr_1;
				
				-- Verificando se não existe a operação de commit
				IF time_commit IS NULL THEN
					time_commit := 1000000000;
				END IF;
				
				FOR schedule_record_fim IN SELECT * FROM "Schedule" AS s WHERE (
							s."time" > time_id_1 AND
							s."time" < time_commit 	AND 
							s."attr" = attr_1 AND 
							s."op" != 'C' AND 
							s."#t" != tr_1
						) LOOP
					
					IF op_1 = 'R' AND schedule_record_fim."op" = 'W' THEN
						INSERT INTO "node"
						VALUES(tr_1, schedule_record_fim."#t");
						
					ELSIF op_1 = 'W' THEN
						INSERT INTO "node"
						VALUES(tr_1, schedule_record_fim."#t");
					ELSE
						CONTINUE;
					END IF;
				END LOOP;
			END IF;
        END LOOP;
		
		--Algoritmo para detecção de ciclos
		EXECUTE 'WITH RECURSIVE search_graph(t_inicio, t_fim, depth, path, cycle) AS (
			SELECT g.t_inicio, g.t_fim, 1,
				ARRAY[g.t_inicio],
				false
			FROM "node" g
			UNION ALL
			SELECT g.t_inicio, g.t_fim, sg.depth + 1,
				path || g.t_inicio,
				g.t_inicio = ANY(path)
			FROM "node" g, search_graph sg
			WHERE g.t_inicio = sg.t_fim AND NOT cycle
		)
		SELECT count(*) FROM search_graph where cycle = TRUE' INTO loops;
		DROP TABLE "node";
		  IF loops > 0 THEN
			RETURN 0;
		ELSE
			RETURN 1;
		END IF;
    END;
$$ LANGUAGE plpgsql;


-- Example_01 (PostgreSQL 10)
-- Resultado: 0
TRUNCATE TABLE "Schedule";

INSERT INTO "Schedule" ("time", "#t", "op", "attr") VALUES
(1, 1,  'R',  'X'),
(2, 2,  'R',  'X'),
(3, 2,  'W',  'X'),
(4, 1,  'W',  'X'),
(5, 2,  'C',  '-'),
(6, 1,  'C',  '-');

-- calling function
SELECT testeEquivalenciaPorConflito() AS resp;


-- example_02 (PostgreSQL 10)
-- Resultado: 1
TRUNCATE TABLE "Schedule";

INSERT INTO "Schedule" ("time", "#t", "op", "attr") VALUES
(7, 3,  'R',  'X'),
(8, 3,  'R',  'Y'),
(9, 4,  'R',  'X'),
(10,  3,  'W',  'Y'),
(11,  4,  'C',  '-'),
(12,  3,  'C',  '-');

-- calling function
SELECT testeEquivalenciaPorConflito() AS resp;


-- example_03 (PostgreSQL 10)
-- Resultado: 1
TRUNCATE TABLE "Schedule";

INSERT INTO "Schedule" ("time", "#t", "op", "attr") VALUES
(1, 1,  'R',  'A'),
(2, 1,  'W',  'A'),
(3, 1,  'R',  'B'),
(4, 1,  'W',  'B'),
(5, 1,  'C',  '-'),
(6, 2,  'R',  'A'),
(7, 2,  'W',  'A'),
(8, 2,  'R',  'B'),
(9, 2,  'W',  'B'),
(10, 2,  'C',  '-');

-- calling function
SELECT testeEquivalenciaPorConflito() AS resp;

-- example_04 (PostgreSQL 10)
-- Resultado: 0
TRUNCATE TABLE "Schedule";

INSERT INTO "Schedule" ("time", "#t", "op", "attr") VALUES
(1, 1,  'R',  'A'),
(2, 2,  'R',  'A'),
(3, 2,  'W',  'A'),
(4, 1,  'W',  'A'),
(5, 1,  'R',  'B'),
(6, 1,  'W',  'B'),
(7, 2,  'R',  'B'),
(8, 2,  'W',  'B'),
(9, 1,  'C',  '-'),
(10, 2,  'C',  '-');

-- calling function
SELECT testeEquivalenciaPorConflito() AS resp;


-- example_05 (PostgreSQL 10)
-- Resultado: 0
TRUNCATE TABLE "Schedule";

INSERT INTO "Schedule" ("time", "#t", "op", "attr") VALUES
(1, 1,  'R',  'A'),
(2, 2,  'W',  'A'),
(3, 1,  'W',  'A'),
(4, 3,  'R',  'B'),
(5, 1,  'W',  'B'),
(6, 2,  'W',  'B'),
(7, 3,  'W',  'B'),
(8, 1,  'C',  '-'),
(9, 2,  'C',  '-'),
(10, 3,  'C',  '-');

-- calling function
SELECT testeEquivalenciaPorConflito() AS resp;

-- example_06 (PostgreSQL 10)
-- Resultado: 0
TRUNCATE TABLE "Schedule";

INSERT INTO "Schedule" ("time", "#t", "op", "attr") VALUES
(1, 1,  'R',  'X'),
(2, 1,  'W',  'X'),
(3, 2,  'R',  'X'),
(4, 3,  'R',  'Y'),
(5, 2,  'W',  'X'),
(6, 2,  'R',  'Y'),
(7, 3,  'W',  'Y'),
(8, 2,  'W',  'Y');

-- calling function
SELECT testeEquivalenciaPorConflito() AS resp;

-- example_07 (PostgreSQL 10)
-- Resultado: 1
TRUNCATE TABLE "Schedule";

INSERT INTO "Schedule" ("time", "#t", "op", "attr") VALUES
(1, 1,  'R',  'A'),
(2, 1,  'W',  'A'),
(3, 2,  'R',  'A'),
(4, 2,  'W',  'A'),
(5, 1,  'C',  '-'),
(6, 3,  'R',  'B'),
(7, 3,  'W',  'B'),
(8, 2,  'R',  'B'),
(9, 2,  'W',  'B'),
(10, 3,  'C',  '-'),
(11, 2,  'C',  '-');

-- calling function
SELECT testeEquivalenciaPorConflito() AS resp;