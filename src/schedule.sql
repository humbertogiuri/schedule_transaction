-- Schedule (PostgreSQL 10)
CREATE TABLE "Schedule" (
	"time" integer,
	"#t" integer NOT NULL,
	"op" character NOT NULL,
	"attr" character NOT NULL,
	UNIQUE ("time")
);