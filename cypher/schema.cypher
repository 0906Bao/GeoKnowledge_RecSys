// Neo4j Server 4.4/5.x. Chạy trong Browser của DBMS mới.
CREATE CONSTRAINT concept_id_unique IF NOT EXISTS FOR (n:Concept) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT property_id_unique IF NOT EXISTS FOR (n:Property) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT theorem_id_unique IF NOT EXISTS FOR (n:Theorem) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT formula_id_unique IF NOT EXISTS FOR (n:Formula) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT tip_id_unique IF NOT EXISTS FOR (n:Tip) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT exercise_id_unique IF NOT EXISTS FOR (n:Exercise) REQUIRE n.id IS UNIQUE;
CREATE INDEX concept_name_index IF NOT EXISTS FOR (n:Concept) ON (n.name);
CREATE INDEX exercise_difficulty_index IF NOT EXISTS FOR (n:Exercise) ON (n.difficulty);
