// Kiểm tra dữ liệu và số liên kết trên từng hình.
MATCH (c:Concept)
OPTIONAL MATCH (c)-[:HAS_PROPERTY]->(p:Property)
WITH c,count(DISTINCT p) AS properties
OPTIONAL MATCH (c)-[:HAS_THEOREM]->(t:Theorem)
WITH c,properties,count(DISTINCT t) AS theorems
OPTIONAL MATCH (c)-[:HAS_FORMULA]->(f:Formula)
WITH c,properties,theorems,count(DISTINCT f) AS formulas
OPTIONAL MATCH (c)-[:HAS_TIP]->(tip:Tip)
WITH c,properties,theorems,formulas,count(DISTINCT tip) AS tips
OPTIONAL MATCH (c)-[:HAS_EXERCISE]->(e:Exercise)
RETURN c.id AS id,c.name AS concept,properties,theorems,formulas,tips,count(DISTINCT e) AS exercises
ORDER BY c.sort_order;

// Kiểm tra phân cấp trực tiếp.
MATCH (child:Concept)-[:IS_A]->(parent:Concept)
RETURN child.name AS child,parent.name AS parent ORDER BY parent.name,child.name;
