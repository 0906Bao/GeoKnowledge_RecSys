import os
import logging

from flask import (
    Flask, render_template, request, jsonify, redirect, url_for, flash
)
from neo4j import GraphDatabase
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv(
    "FLASK_SECRET_KEY",
    "development-only-change-this-secret"
)
app.logger.setLevel(logging.INFO)

URI = os.getenv("NEO4J_URI", "bolt://127.0.0.1:7687")
USER = os.getenv("NEO4J_USER", "neo4j")
PASSWORD = os.getenv("NEO4J_PASSWORD", "")
DATABASE = os.getenv("NEO4J_DATABASE", "neo4j")

driver = None
connection_error = ""

try:
    driver = GraphDatabase.driver(URI, auth=(USER, PASSWORD))
    driver.verify_connectivity()
except Exception as exc:
    connection_error = str(exc)
    app.logger.error("Không kết nối được Neo4j: %s", connection_error)
    driver = None


def query(cypher, params=None):
    """Chạy truy vấn Neo4j và trả về danh sách dict."""
    if driver is None:
        raise RuntimeError(
            "Chưa kết nối Neo4j. Kiểm tra trạng thái DBMS và file .env."
        )
    with driver.session(database=DATABASE) as session:
        return [record.data() for record in session.run(cypher, params or {})]


def concepts(q=""):
    return query(
        """
        MATCH (c:Concept)
        WHERE $q = ''
           OR toLower(coalesce(c.name, '')) CONTAINS toLower($q)
           OR toLower(coalesce(c.definition, '')) CONTAINS toLower($q)
        RETURN c{.*} AS item
        ORDER BY coalesce(c.sort_order, 999), c.name
        LIMIT 100
        """,
        {"q": q},
    )


def get_concept_graph():
    """
    Lấy đồ thị phân cấp.
    Chấp nhận cả IS_A và IS_SPECIAL_CASE_OF để tương thích dữ liệu cũ.
    Chỉ trả các cạnh có đủ id hai đầu; không tạo cạnh giả cho node cô lập.
    """
    rows = query(
        """
        MATCH (c:Concept)
        OPTIONAL MATCH (c)-[r]->(p:Concept)
        WHERE type(r) IN ['IS_A', 'IS_SPECIAL_CASE_OF']
        RETURN
            collect(DISTINCT {
                id: c.id,
                name: coalesce(c.name, c.id)
            }) AS nodes,
            collect(DISTINCT CASE
                WHEN r IS NOT NULL AND p IS NOT NULL
                THEN {
                    source: c.id,
                    target: p.id,
                    label: 'IS_A',
                    original_type: type(r)
                }
                ELSE null
            END) AS raw_edges
        """
    )
    if not rows:
        return {"nodes": [], "edges": []}

    nodes = [
        node for node in (rows[0].get("nodes") or [])
        if node and node.get("id")
    ]

    # Khử cạnh trùng nếu DB đồng thời có IS_A và IS_SPECIAL_CASE_OF
    # giữa cùng một cặp khái niệm.
    edges_by_pair = {}
    for edge in rows[0].get("raw_edges") or []:
        if not edge or not edge.get("source") or not edge.get("target"):
            continue
        key = (edge["source"], edge["target"])
        if key not in edges_by_pair:
            edges_by_pair[key] = edge

    return {"nodes": nodes, "edges": list(edges_by_pair.values())}


@app.context_processor
def globals_for_templates():
    return {
        "db_connected": driver is not None,
        "connection_error": connection_error,
    }


@app.route("/")
def home():
    q = request.args.get("q", "").strip()
    items, graph, tips = [], {"nodes": [], "edges": []}, []
    try:
        items = [row["item"] for row in concepts(q)]
        graph = get_concept_graph()
        tips = [
            row["tip"]
            for row in query(
                """
                MATCH (t:Tip)
                WHERE coalesce(t.status, 'published') = 'published'
                RETURN t{.*} AS tip
                ORDER BY t.created_at DESC
                LIMIT 4
                """
            )
        ]
    except Exception as exc:
        app.logger.exception("Lỗi tải trang chủ")
        flash(str(exc), "error")

    return render_template(
        "home.html", items=items, graph=graph, tips=tips, q=q
    )


@app.route("/concept/<cid>")
def concept(cid):
    try:
        rows = query(
            """
            MATCH (c:Concept {id: $id})
            OPTIONAL MATCH (c)-[:HAS_PROPERTY]->(p:Property)
            WITH c, collect(DISTINCT p{.*}) AS properties
            OPTIONAL MATCH (c)-[:HAS_THEOREM]->(t:Theorem)
            WITH c, properties, collect(DISTINCT t{.*}) AS theorems
            OPTIONAL MATCH (c)-[:HAS_FORMULA]->(f:Formula)
            WITH c, properties, theorems, collect(DISTINCT f{.*}) AS formulas
            OPTIONAL MATCH (c)-[:HAS_TIP]->(tip:Tip)
            WITH c, properties, theorems, formulas,
                 collect(DISTINCT tip{.*}) AS tips
            OPTIONAL MATCH (c)-[:HAS_EXERCISE]->(e:Exercise)
            RETURN c{.*} AS concept,
                   properties, theorems, formulas, tips,
                   collect(DISTINCT e{.*}) AS exercises
            """,
            {"id": cid},
        )
        if not rows:
            flash("Không tìm thấy khái niệm.", "warning")
            return redirect(url_for("home"))
        return render_template("concept.html", d=rows[0])
    except Exception as exc:
        app.logger.exception("Lỗi tải khái niệm %s", cid)
        flash(str(exc), "error")
        return redirect(url_for("home"))


@app.route("/practice")
def practice():
    cid = request.args.get("concept", "").strip()
    difficulty = request.args.get("difficulty", "").strip()

    items = []
    concept_items = []

    try:
        # Lấy danh sách bài tập đã xuất bản
        rows = query(
            """
            MATCH (e:Exercise)
            WHERE coalesce(e.status, 'published') = 'published'
              AND ($d = '' OR e.difficulty = $d)
              AND (
                $c = ''
                OR EXISTS {
                    MATCH (:Concept {id: $c})-[:HAS_EXERCISE]->(e)
                }
              )
            RETURN e{.*} AS item
            ORDER BY e.difficulty, e.id
            """,
            {"c": cid, "d": difficulty},
        )

        items = [row["item"] for row in rows]

        # Lấy danh sách khái niệm
        concept_rows = concepts()
        concept_items = [row["item"] for row in concept_rows]

    except Exception:
        app.logger.exception(
            "Lỗi tải bài luyện tập: concept=%s, difficulty=%s",
            cid,
            difficulty,
        )
        flash(
            "Không thể tải bài tập do lỗi dữ liệu hoặc kết nối. "
            "Vui lòng kiểm tra log của máy chủ.",
            "error",
        )

    return render_template(
        "practice.html",
        items=items,
        concepts=concept_items,
        cid=cid,
        difficulty=difficulty,
    )


@app.post("/api/exercise/<eid>/submit")
def submit(eid):
    payload = request.get_json(silent=True) or {}
    answer = str(payload.get("answer", "")).strip()

    try:
        rows = query(
            """
            MATCH (e:Exercise {id: $id})
            OPTIONAL MATCH (e)-[:APPLIES_TO]->(target)
            RETURN e{.*} AS exercise,
                   collect(DISTINCT CASE
                     WHEN target IS NOT NULL THEN {
                       id: target.id,
                       name: coalesce(
                         target.name, target.content, target.statement,
                         target.id
                       ),
                       label: head(labels(target))
                     }
                     ELSE null
                   END) AS related
            """,
            {"id": eid},
        )
        if not rows:
            return jsonify({"error": "Không tìm thấy bài tập"}), 404

        exercise = rows[0]["exercise"]
        expected = str(exercise.get("correct_answer", "")).strip()

        def normalize(value):
            return " ".join(
                str(value).casefold().replace(",", " ").split()
            ).strip()

        correct = bool(expected) and normalize(answer) == normalize(expected)

        recommendations = query(
            """
            MATCH (e:Exercise {id: $id})
            OPTIONAL MATCH (c:Concept)-[:HAS_EXERCISE]->(e)
            WITH e, collect(DISTINCT c) AS source_concepts
            MATCH (n:Exercise)
            WHERE n.id <> e.id
              AND coalesce(n.status, 'published') = 'published'
              AND (
                ($correct = true AND n.difficulty IN ['Trung bình', 'Khó'])
                OR
                ($correct = false AND n.difficulty IN ['Dễ', 'Trung bình'])
              )
              AND (
                size(source_concepts) = 0
                OR EXISTS {
                    MATCH (c2:Concept)-[:HAS_EXERCISE]->(n)
                    WHERE c2 IN source_concepts
                }
              )
            RETURN collect(DISTINCT n{.*})[0..3] AS items
            """,
            {"id": eid, "correct": correct},
        )

        return jsonify({
            "correct": correct,
            "correct_answer": expected,
            "solution": exercise.get("solution", ""),
            "solution_steps": exercise.get("solution_steps", []),
            "related": [item for item in rows[0]["related"] if item],
            "recommendations": (
                recommendations[0]["items"] if recommendations else []
            ),
        })
    except Exception as exc:
        app.logger.exception("Lỗi chấm bài tập %s", eid)
        return jsonify({"error": "Không thể chấm bài lúc này."}), 500


@app.get("/api/graph")
def graph_api():
    """API cho thư viện đồ thị ở frontend."""
    try:
        return jsonify(get_concept_graph())
    except Exception as exc:
        app.logger.exception("Lỗi tải API đồ thị")
        return jsonify({
            "error": str(exc),
            "nodes": [],
            "edges": [],
        }), 503


@app.route("/admin", methods=["GET", "POST"])
def admin():
    if request.method == "POST":
        kind = request.form.get("kind", "").strip()
        item_id = request.form.get("id", "").strip()
        concept_id = request.form.get("concept_id", "").strip()

        try:
            if not item_id:
                raise ValueError("ID là bắt buộc.")

            if kind == "concept":
                name = request.form.get("name", "").strip()
                if not name:
                    raise ValueError("Tên khái niệm là bắt buộc.")
                query(
                    """
                    MERGE (n:Concept {id: $id})
                    SET n.name = $name,
                        n.definition = $definition,
                        n.type = $type,
                        n.topic = 'Tu_giac'
                    """,
                    {
                        "id": item_id,
                        "name": name,
                        "definition": request.form.get("definition", "").strip(),
                        "type": request.form.get("type", "Hình chính"),
                    },
                )

            elif kind == "property":
                query(
                    """
                    MATCH (c:Concept {id: $cid})
                    MERGE (n:Property {id: $id})
                    SET n.content = $content, n.category = $category
                    MERGE (c)-[:HAS_PROPERTY]->(n)
                    """,
                    {
                        "id": item_id,
                        "cid": concept_id,
                        "content": request.form.get("content", "").strip(),
                        "category": request.form.get("category", "Tính chất"),
                    },
                )

            elif kind == "theorem":
                query(
                    """
                    MATCH (c:Concept {id: $cid})
                    MERGE (n:Theorem {id: $id})
                    SET n.name = $name,
                        n.statement = $statement,
                        n.conditions = $conditions,
                        n.conclusion = $conclusion
                    MERGE (c)-[:HAS_THEOREM]->(n)
                    """,
                    {
                        "id": item_id,
                        "cid": concept_id,
                        "name": request.form.get("name", "").strip(),
                        "statement": request.form.get("statement", "").strip(),
                        "conditions": request.form.get("conditions", "").strip(),
                        "conclusion": request.form.get("conclusion", "").strip(),
                    },
                )

            elif kind == "formula":
                query(
                    """
                    MATCH (c:Concept {id: $cid})
                    MERGE (n:Formula {id: $id})
                    SET n.name = $name,
                        n.expression = $expression,
                        n.variables = $variables,
                        n.conditions = $conditions
                    MERGE (c)-[:HAS_FORMULA]->(n)
                    """,
                    {
                        "id": item_id,
                        "cid": concept_id,
                        "name": request.form.get("name", "").strip(),
                        "expression": request.form.get("expression", "").strip(),
                        "variables": [
                            line.strip()
                            for line in request.form.get("variables", "").splitlines()
                            if line.strip()
                        ],
                        "conditions": request.form.get("conditions", "").strip(),
                    },
                )

            elif kind == "exercise":
                query(
                    """
                    MATCH (c:Concept {id: $cid})
                    MERGE (n:Exercise {id: $id})
                    SET n.question = $question,
                        n.exercise_type = $etype,
                        n.difficulty = $difficulty,
                        n.options = $options,
                        n.correct_answer = $answer,
                        n.solution = $solution,
                        n.solution_steps = $steps,
                        n.status = 'published'
                    MERGE (c)-[:HAS_EXERCISE]->(n)
                    MERGE (n)-[:APPLIES_TO]->(c)
                    """,
                    {
                        "id": item_id,
                        "cid": concept_id,
                        "question": request.form.get("question", "").strip(),
                        "etype": request.form.get("exercise_type", "MCQ"),
                        "difficulty": request.form.get("difficulty", "Dễ"),
                        "options": [
                            line.strip()
                            for line in request.form.get("options", "").splitlines()
                            if line.strip()
                        ],
                        "answer": request.form.get("correct_answer", "").strip(),
                        "solution": request.form.get("solution", "").strip(),
                        "steps": [
                            line.strip()
                            for line in request.form.get("solution_steps", "").splitlines()
                            if line.strip()
                        ],
                    },
                )
            else:
                raise ValueError("Loại nội dung không hợp lệ.")

            flash("Đã lưu nội dung vào Neo4j.", "success")

        except Exception as exc:
            app.logger.exception("Lỗi lưu nội dung quản trị")
            flash("Lưu thất bại: " + str(exc), "error")

        return redirect(url_for("admin"))

    try:
        concept_items = [row["item"] for row in concepts()]
    except Exception as exc:
        concept_items = []
        flash(str(exc), "error")

    return render_template("admin.html", concepts=concept_items)


@app.get("/health")
def health():
    return jsonify({
        "app": "ok",
        "neo4j": driver is not None,
        "database": DATABASE,
        "connection_error": connection_error if driver is None else None,
    })


@app.teardown_appcontext
def close_driver_on_app_shutdown(exception=None):
    # Không đóng driver tại teardown mỗi request vì driver được dùng chung.
    # Driver được đóng khi tiến trình Flask kết thúc.
    return None


if __name__ == "__main__":
    app.run(
        host=os.getenv("FLASK_HOST", "127.0.0.1"),
        port=int(os.getenv("FLASK_PORT", "5000")),
        debug=os.getenv("FLASK_DEBUG", "false").lower() == "true",
    )
